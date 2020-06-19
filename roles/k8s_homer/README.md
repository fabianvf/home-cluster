k8s_homer
=========

Configures the homer dashboard in Kubernetes

Requirements
------------

- Requires the openshift python package

Role Variables
--------------

cluster_subdomain - The subdomain to set for ingresses created during the execution of this role.

Dependencies
------------

Requires the community.kubernetes ansible collection

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: fabianvf.k8s_homer, homer_host: dashboard.example.org }

License
-------

AGPL-3.0
