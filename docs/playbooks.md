## Playbook structure

```
site.yml
 |-- foreman.yml
 |     |- roles/foreman
 |     |- roles/reboot
 |-- nodes.yml
       |- atomic.yml
       |  |- roles/atomic_upgrade
       |  |- roles/reboot
       |- openshift_wildcard.yml
       |  |- TBD
       |- openshift.yml
          |- openshift-ansible/playbooks/byo/config.yml
         
```
