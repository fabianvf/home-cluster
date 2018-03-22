# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|

  nodes = (1..(ENV["NUM_NODES"]||3).to_i).map { |i| "node#{i-1}.example.net"}
  verbosity = ENV["VERBOSITY"]||""

  config.hostmanager.enabled = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = false

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: 'rsync',
    }
  end

  config.vm.define 'master.example.net', :primary => true do |master|
    master.vm.box = "dongsupark/coreos-stable"
    master.vm.hostname = 'master.example.net'
    master.hostmanager.manage_host = true
    master.hostmanager.manage_guest = false
    master.vm.network :private_network,
      :mac => "52:11:22:33:44:41",
      :ip => '192.168.47.11',
      :libvirt__network_name => "coreos-cluster",
      :libvirt__domain_name => "example.net",
      :libvirt__dhcp_enabled => true,
      :libvirt__netmask => "255.255.255.0",
      :libvirt__dhcp_bootp_file => "undionly.kpxe",
      :libvirt__dhcp_bootp_server => "192.168.47.11"

    master.vm.synced_folder '.', '/vagrant', disabled: true

    master.vm.provision :file, :source => "~/.ssh/id_rsa.pub", :destination => "/tmp/key"
    master.vm.provision :shell, :inline => <<-EOF
      tail -n +2 /home/core/.ssh/authorized_keys > /home/core/.ssh/authorized_keys.d/vagrant
      cp /tmp/key /home/core/.ssh/authorized_keys.d/home-cluster
      mkdir -p /root/.ssh/
      cp -R /home/core/.ssh/authorized_keys.d /root/.ssh/
      update-ssh-keys -u root && update-ssh-keys -u core
      update_engine_client -update && shutdown -r now
    EOF
    master.vm.provision :ansible do |ansible|
      ansible.host_vars = {
        'matchbox.example.net' => {
          'matchbox_dns_interface': 'eth1',
          'matchbox_host': 'master.example.net',
          'github_user': ENV['GITHUB_USER'],
          'github_password': ENV['GITHUB_PASSWORD']
        }
      }
      ansible.verbose = verbosity
      ansible.playbook = 'playbooks/matchbox.yml'
      ansible.become = true
      ansible.limit = 'all,localhost'
      ansible.inventory_path = './inventory'
      ansible.extra_vars = 'vagrant.config.yml' if File.file? 'vagrant.config.yml'
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
        # TODO: Need a dynamic inventory script for this
        run "ansible-playbook playbooks/nodes.yml -e '#{extra_vars.to_json}' #{ File.file?('vagrant.config.yml') ? '-e @vagrant.config.yml' : ''} -i inventory -l 'all,localhost' #{verbosity == '' ? '' : '-' + verbosity}"
      end
    end
  end


  nodes.each do |name|
    config.vm.define name, :autostart => false do |node|
      node.hostmanager.manage_guest = true
      node.hostmanager.manage_host = false
      node.vm.hostname = name

      node.vm.provider :libvirt do |domain|
        domain.storage :file, :size => '80G', :type => 'raw'
        domain.storage :file, :size => '40G', :type => 'raw'
        domain.mgmt_attach = 'false'
        domain.management_network_name = 'coreos-cluster'
        domain.management_network_address = "192.168.47.0/24"
        domain.management_network_mode = "nat"
        domain.boot 'hd'
        domain.boot 'network'
      end
    end
  end


  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 4000
    libvirt.cpus = `grep -c ^processor /proc/cpuinfo`.to_i
  end
end
