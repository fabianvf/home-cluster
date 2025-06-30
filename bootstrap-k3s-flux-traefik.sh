#!/bin/bash
set -euo pipefail

REQUIRED_VARS=(CLOUDFLARE_API_TOKEN CLOUDFLARE_ZONE_ID GITHUB_TOKEN GITHUB_REPO GITHUB_BRANCH)
for VAR in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!VAR:-}" ]]; then
    echo "ERROR: $VAR is not set. Please export all required env vars before running."
    exit 1
  fi
done
if [[ -z "${GITHUB_USER:-}" ]]; then
  GITHUB_USER=${GITHUB_REPO%%/*}
fi

echo "All required environment variables found."

echo "[1/7] Updating system and installing dependencies..."
sudo dnf -y update
sudo dnf -y install curl git jq openssl

echo "[2/7] Disabling firewalld for cluster networking (re-enable/tune later if needed)..."
sudo systemctl disable --now firewalld || true

export K3S_KUBECONFIG_MODE="644"

echo "[3/7] Installing K3s (with Traefik ingress, default)..."
curl -sfL https://get.k3s.io | sh -

sudo chown $USER /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
ln -sf /etc/rancher/k3s/k3s.yaml ~/.kube/config
export KUBECONFIG=~/.kube/config

echo "Waiting for K3s to finish bootstrapping..."
sleep 30

echo "[4/7] Setting up Cloudflare ACME for Traefik wildcard TLS..."

kubectl -n kube-system delete secret cloudflare-api-token-secret --ignore-not-found

kubectl -n kube-system create secret generic cloudflare-api-token-secret \
  --from-literal=CLOUDFLARE_DNS_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

TRAEFIK_VALUES=$(cat <<EOF
additionalArguments:
  - "--certificatesresolvers.cloudflare.acme.dnschallenge=true"
  - "--certificatesresolvers.cloudflare.acme.dnschallenge.provider=cloudflare"
  - "--certificatesresolvers.cloudflare.acme.email=admin@playerof.games"
  - "--certificatesresolvers.cloudflare.acme.storage=/data/acme.json"
  - "--certificatesresolvers.cloudflare.acme.dnschallenge.resolvers=1.1.1.1:53"
  - "--entrypoints.websecure.http.tls.certresolver=cloudflare"
  - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
  - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
$( [[ "${LETSENCRYPT_STAGING:-false}" == "true" ]] && echo '  - "--certificatesresolvers.cloudflare.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory"' )
env:
  - name: CLOUDFLARE_DNS_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: cloudflare-api-token-secret
        key: CLOUDFLARE_DNS_API_TOKEN
EOF
)

cat <<EOF | kubectl apply -n kube-system -f -
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
spec:
  valuesContent: |
$(echo "$TRAEFIK_VALUES" | sed 's/^/    /')
EOF

echo "Restarting Traefik to pick up ACME config..."
kubectl -n kube-system delete pod -l app.kubernetes.io/name=traefik

# --- FLUX INSTALL & GITOPS BOOTSTRAP ---

echo "[5/7] Installing Flux CD and bootstrapping GitOps repo..."

curl -s https://fluxcd.io/install.sh | sudo bash

export GITHUB_AUTH_TOKEN="$GITHUB_TOKEN"
flux check --pre

flux bootstrap github \
  --owner=${GITHUB_USER} \
  --repository=${GITHUB_REPO#*/} \
  --branch=${GITHUB_BRANCH} \
  --personal \
  --path=clusters/homelab \
  --token-auth

# --- HELLO-WORLD INGRESS DEMO ---

echo "[6/7] Deploying hello-world app (https://hello.playerof.games)..."

kubectl create namespace demo || true

cat <<EOF | kubectl apply -n demo -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: hashicorp/http-echo
        args:
          - "-text=Hello, World from K3s + Flux + Traefik + Cloudflare!"
        ports:
          - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world
spec:
  type: ClusterIP
  selector:
    app: hello-world
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: hello.playerof.games
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-world
            port:
              number: 80
  tls:
  - hosts:
      - hello.playerof.games
    secretName: hello-tls
EOF

echo "[7/7] Waiting for everything to become available..."

# Wait for Traefik to be fully running
echo "Waiting for Traefik deployment to be ready..."
kubectl -n kube-system rollout status deployment/traefik --timeout=180s

# Wait for hello-world deployment to be ready
echo "Waiting for hello-world deployment to be ready..."
kubectl -n demo rollout status deployment/hello-world --timeout=90s

# Wait for Ingress to be assigned
echo "Waiting for hello-world ingress to be assigned..."
for i in {1..30}; do
  ADDR=$(kubectl -n demo get ingress hello-world -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  [ -z "$ADDR" ] && ADDR=$(kubectl -n demo get ingress hello-world -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ ! -z "$ADDR" ]; then
    echo "Ingress assigned: $ADDR"
    break
  fi
  sleep 2
done

# Update /etc/hosts with the test domain
VM_IP=$(hostname -I | awk '{print $1}')
if ! grep -q "hello.playerof.games" /etc/hosts; then
  echo "$VM_IP hello.playerof.games" | sudo tee -a /etc/hosts
  echo "Added $VM_IP hello.playerof.games to /etc/hosts"
fi

# Poll for ACME cert from Traefik
echo "Polling Traefik for a valid ACME certificate on https://hello.playerof.games..."
success=0
for i in {1..36}; do  # Wait up to 3 minutes (36 * 5s)
  CERT_ISSUER=$(echo | openssl s_client -connect hello.playerof.games:443 -servername hello.playerof.games 2>/dev/null | openssl x509 -noout -issuer || true)
  CERT_SUBJ=$(echo | openssl s_client -connect hello.playerof.games:443 -servername hello.playerof.games 2>/dev/null | openssl x509 -noout -subject || true)
  CERT_EXP=$(echo | openssl s_client -connect hello.playerof.games:443 -servername hello.playerof.games 2>/dev/null | openssl x509 -noout -enddate || true)
  echo "Attempt $i: Issuer: $CERT_ISSUER"
  if [[ "$CERT_ISSUER" =~ "Let's Encrypt" || "$CERT_ISSUER" =~ "Fake LE" || "$CERT_ISSUER" =~ "STAGING" ]]; then
    echo "Valid ACME cert is being served!"
    success=1
    break
  fi
  sleep 5
done

echo
echo "==================================================================================="
if [[ $success -eq 1 ]]; then
  echo "SUCCESS: Access https://hello.playerof.games to verify the TLS certificate."
  echo "Cert subject: $CERT_SUBJ"
  echo "Cert issuer:  $CERT_ISSUER"
  echo "Cert expires: $CERT_EXP"
  echo
  echo "If this is a Let's Encrypt (or staging/Fake LE) cert, you're DONE and cert automation is fully working."
else
  echo "ERROR: Valid ACME certificate was not issued by Traefik within the expected time."
  echo "Check the Traefik logs and your ACME/Cloudflare config."
  exit 2
fi
echo "==================================================================================="
