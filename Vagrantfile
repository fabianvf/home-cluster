# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|

  nodes = (1..(ENV["NUM_NODES"]||3).to_i).map {|i| (i == 1) ? "master.example.org" : "node#{i-1}.example.org"}
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

  if !ENV['ONLY_NODES']
    config.vm.define 'foreman.example.org', :primary => true do |foreman|
      foreman.vm.box = "centos/7"
      foreman.vm.hostname = 'foreman.example.org'
      foreman.hostmanager.enabled = true
      foreman.hostmanager.manage_host = true
      foreman.vm.network :private_network,
        :mac => "52:11:22:33:44:41",
        :ip => '192.168.17.11',
        :libvirt__network_name => "home-cluster",
        :libvirt__dhcp_enabled => true,
        :libvirt__netmask => "255.255.255.0",
        :libvirt__dhcp_bootp_file => "pxelinux.0",
        :libvirt__dhcp_bootp_server => "192.168.17.11"

      foreman.vm.synced_folder '.', '/vagrant', disabled: true

      foreman.vm.provision :file, :source => "~/.ssh/id_rsa.pub", :destination => "/tmp/key"
      foreman.vm.provision :shell, :inline => "cat /tmp/key >> /home/vagrant/.ssh/authorized_keys;  mkdir -p /root/.ssh ; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/authorized_keys"

      foreman.vm.provision :ansible do |ansible|
        ansible.verbose = verbosity
        ansible.playbook = 'playbooks/foreman.yml'
        ansible.become = true
        ansible.limit = 'all,localhost'
        ansible.inventory_path = './inventory'
        ansible.extra_vars = {"foreman_dns_interface": "eth1"}
      end

      if Vagrant.has_plugin?("vagrant-triggers") and nodes.length > 0
        config.trigger.after [:provision, :up] do
          nodes.each do |node|
            run "vagrant up #{node}"
            sleep 10
          end
          extra_vars = {
            :number_of_hosts => nodes.length,
            :prompt_for_hosts => false,
            :modify_etc_hosts => true,
            :glusterfs_wipe => true
          }
          run "ansible-playbook playbooks/nodes.yml -e '#{extra_vars.to_json}' -i inventory -l 'all,localhost' #{verbosity == '' ? '' : '-' + verbosity}"
        end
      end
    end
  end

  nodes.each do |name|
    config.vm.define name, :autostart => false do |node|
      node.hostmanager.manage_guest = false
      node.hostmanager.manage_host = false
      node.vm.hostname = name

      node.vm.provider :libvirt do |domain|
        domain.storage :file, :size => '80G', :type => 'raw'
        domain.storage :file, :size => '40G', :type => 'raw'
        domain.mgmt_attach = 'false'
        domain.management_network_name = 'home-cluster'
        domain.management_network_address = "192.168.17.0/24"
        domain.management_network_mode = "nat"
        domain.boot 'network'
        domain.boot 'hd'
      end
    end
  end


  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 4000
    libvirt.cpus = `grep -c ^processor /proc/cpuinfo`.to_i
  end
end
