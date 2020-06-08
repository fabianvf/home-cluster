k8s_nginx_ingress
=========

Configures the ingress-nginx ingress controller along with metallb for Kubernetes

Requirements
------------

- Requires the openshift python package

Role Variables
--------------

cluster_subdomain - The subdomain to set for ingresses created during the execution of this role.
metallb_ip_range - A range of IP addresses reserved for metallb to assign to LoadBalancer services, ex '192.168.17.50-192.168.17.100'

Dependencies
------------

Requires the community.kubernetes ansible collection

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: fabianvf.k8s_nginx_ingress, cluster_subdomain: example.org, metallb_ip_range: '192.168.17.50-192.168.17.100' }

License
-------

AGPL-3.0
