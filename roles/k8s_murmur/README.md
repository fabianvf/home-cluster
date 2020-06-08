k8s_murmur
=========

Installs a murmur server on a Kubernetes cluster

Requirements
------------

- Requires the openshift python package

Role Variables
--------------

No variables

Dependencies
------------

Requires the community.kubernetes ansible collection

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: first_node
      roles:
         - { role: fabianvf.k8s_murmur }

License
-------

AGPL-3.0
