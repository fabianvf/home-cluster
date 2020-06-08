k8s_velero
=========

description: Installs velero with minio as an NFS gateway for cluster backup

Requirements
------------

- Requires the openshift python package
- Requires the helm binary

Role Variables
--------------

cluster_subdomain - The subdomain to set for ingresses created during the execution of this role.
velero_version - The velero version to install
artifacts_dir - A existing directory to store generated password/userids

Dependencies
------------

Requires the community.kubernetes ansible collection

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: fabianvf.k8s_velero, cluster_subdomain: example.org, artifacts_dir: ~/artifacts, velero_version: v1.4.0 }

License
-------

AGPL-3.0
