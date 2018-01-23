# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: 'rsync',
    }
  end

  config.vm.define 'foreman.example.org', :primary => true do |foreman|
    foreman.ssh.insert_key = 'true'
    foreman.vm.box = "centos/7"
    foreman.vm.hostname = 'foreman.example.org'
    foreman.vm.network :private_network,
      :mac => "52:11:22:33:44:41",
      :ip => '192.168.17.11',
      :libvirt__network_name => "home-cluster",
      :libvirt__dhcp_enabled => true,
      :libvirt__netmask => "255.255.255.0",
      :libvirt__dhcp_bootp_file => "pxelinux.0",
      :libvirt__dhcp_bootp_server => "192.168.17.11"

    foreman.vm.synced_folder '.', '/vagrant', disabled: true

    foreman.vm.provision :ansible do |ansible|
      ansible.playbook = 'playbooks/foreman.yml'
      ansible.sudo = true
      ansible.inventory_path = './inventory'
      ansible.extra_vars = {"foreman_dns_interface": "eth1"}
    end
  end

  (1..ENV["NUM_NODES"].to_i||3).map { |i| "node#{i}.example.org" }.each do |name|
    config.vm.define name do |node|
      node.hostmanager.manage_guest = false
      node.vm.hostname = name

      node.vm.provider :libvirt do |domain|
        domain.storage :file, :size => '80G', :type => 'qcow2'
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
