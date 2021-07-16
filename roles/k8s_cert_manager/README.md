k8s_rook_ceph
=========

Installs and configures rook-ceph on Kubernetes

Requirements
------------

- Requires the openshift python package

Role Variables
--------------

cluster_subdomain - The subdomain to set for ingresses created during the execution of this role.

storage_metadata_replicas - The number of replicas to use in the metadata storage pool
storage_data_replicas - The number of replicas to use in the data storage bool
storage_block_create - Set to true to configure rook-ceph Block storage
storage_block_default - Set to true to set rook-ceph-block as the default storageclass
storage_cephfs_create - Set to true to configure rook-ceph Filesystem storage
storage_cephfs_default: - Set to true to set rook-cephfs as the default storageclass

Dependencies
------------

Requires the community.kubernetes ansible collection

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: fabianvf.k8s_rook_ceph, cluster_subdomain: example.org, storage_data_replicas: 2 }

License
-------

AGPL-3.0
