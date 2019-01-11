# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  nodes = (1..(ENV["NUM_NODES"]||3).to_i).map {|i| "node#{i}.example.org"}
  verbosity = ENV["VERBOSITY"]||""

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = false
  config.hostmanager.manage_guest = false
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = false

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: 'rsync',
    }
  end

  if (ENV["ATOMIC"] != 'false')
    config.vm.box = "fedora/28-atomic-host"
  else
      config.vm.box = "centos/7"
      config.vm.provision :shell, :inline => <<-EOF
        set -x
        yum install -y python3 libselinux-python epel-release
        yum remove -y python2-docker
        cat > /etc/yum.repos.d/CentOS-OpenShift-Origin-CBS.repo <<- EOF2
    [centos-openshift-origin-testing-cbs]
    name=CentOS OpenShift Origin Testing CBS
    baseurl=https://cbs.centos.org/repos/paas7-openshift-origin310-testing/x86_64/os/
    enabled=1
    gpgcheck=0
    gpgkey=file:///etc/pki/rpm-gpg/openshift-ansible-CentOS-SIG-PaaS
  EOF2
      EOF
  end

  config.vm.provision :file, :source => "~/.ssh/id_rsa.pub", :destination => "/tmp/key"
  config.vm.provision :shell, :inline => <<-EOF
    cat /tmp/key >> /home/vagrant/.ssh/authorized_keys
    mkdir -p /root/.ssh
    cp /home/vagrant/.ssh/authorized_keys /root/.ssh/authorized_keys
    sed -i 's/127.0.0.1.*master.example.org/192.168.17.11 master.example.org/' /etc/hosts
  EOF

  if !ENV['ONLY_NODES']
    config.vm.define 'master.example.org', :primary => true do |master|
      master.vm.hostname = 'master.example.org'
      master.hostmanager.enabled = true
      master.hostmanager.manage_host = true
      master.hostmanager.manage_guest = false
      master.vm.network :private_network,
        :mac => "52:11:22:33:44:41",
        :ip => '192.168.17.11',
        :libvirt__network_name => "home-cluster",
        :libvirt__dhcp_enabled => true,
        :libvirt__netmask => "255.255.255.0",
        :libvirt__dhcp_bootp_server => "192.168.17.11"

      master.vm.provider :libvirt do |domain|
        domain.storage :file, :size => '40G', :type => 'raw'
        domain.storage :file, :size => '40G', :type => 'raw'
      end
      master.vm.synced_folder '.', '/vagrant', disabled: true


      # if machine_id == N
      # machine.vm.provision :ansible do |ansible|
      #   # Disable default limit to connect to all the machines
      #   ansible.limit = "all"
      #   ansible.playbook = "playbook.yml"
      # if Vagrant.has_plugin?("vagrant-triggers") and nodes.length > 0
      #   config.trigger.after [:provision, :up] do
          # nodes.each do |node|
            # run "vagrant up #{node}"
            # sleep 10
          # end
          # extra_vars = {
          #   :number_of_hosts => nodes.length,
          #   :prompt_for_hosts => false,
          #   :modify_etc_hosts => true,
          #   :glusterfs_wipe => true
          # }
          # run "ansible-playbook playbooks/nodes.yml -e '#{extra_vars.to_json}' -i inventory -l 'all,localhost' #{verbosity == '' ? '' : '-' + verbosity}"
        # end
    end
  end

  host_vars = {
    "master.example.org" => {
      "ansible_host" => "192.168.17.11",
      "master_subdomain" => "example.org"
    }
  }
  nodes.each_with_index do |name, idx|
    config.vm.define name, :autostart => true do |node|
      # node.hostmanager.manage_guest = false
      # node.hostmanager.manage_host = false
      node.vm.hostname = name
      node_ip = "192.168.17.#{12 + idx}"

      host_vars[name] = {"ansible_host" => node_ip}

      node.vm.network :private_network,
        :ip => node_ip
      node.vm.provider :libvirt do |domain|
        domain.storage :file, :size => '40G', :type => 'raw'
        domain.storage :file, :size => '40G', :type => 'raw'
        # domain.mgmt_attach = 'false'
        # domain.management_network_name = 'home-cluster'
        # domain.management_network_address = "192.168.17.0/24"
        # domain.management_network_mode = "nat"
        # domain.boot 'network'
        # domain.boot 'hd'
      end
      if idx == nodes.size - 1
        # Kick off provisioning
        node.vm.provision :ansible do |ansible|
          ansible.groups = {
            "first_master" => ["master.example.org"],
            "masters" => ["master.example.org"],
            "nodes" => nodes,
            "OSEv3:children" => ["masters", "nodes"]
          }
          ansible.verbose = verbosity
          ansible.playbook = 'playbooks/deploy.yml'
          ansible.become = true
          ansible.force_remote_user = false
          ansible.limit = 'all,localhost'
          ansible.raw_ssh_args = ["-o IdentityFile=~/.ssh/id_rsa"]
          ansible.host_vars = host_vars
        end
      end
    end
  end


  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 8000
    libvirt.cpus = `grep -c ^processor /proc/cpuinfo`.to_i
  end
end
