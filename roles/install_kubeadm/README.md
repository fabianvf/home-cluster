install_kubeadm
=========

Installs kubeadm and gets the kubelet running and ready for cluster initialization

Requirements
------------

- Requires the openshift python package

Role Variables
--------------

kubernetes_master - Whether the node is a master. Used for determining what to install/what ports to open.
kubernetes_node - Whether the node is a worker. Used for determining what to install/what ports to open.

Dependencies
------------

Requires the community.kubernetes ansible collection

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: nodes
      roles:
         - { role: fabianvf.install_kubeadm, kubernetes_master: yes, kubernetes_node: yes }

License
-------

AGPL-3.0
