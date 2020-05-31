# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  nodes = (1..(ENV["NUM_NODES"]||1).to_i).map {|i| "node#{i}.example.org"}
  verbosity = ENV["VERBOSITY"]||""

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = false

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: 'rsync',
    }
  end

  config.vm.box = "centos/7"

  config.vm.provision :file, :source => "~/.ssh/id_rsa.pub", :destination => "/tmp/key"
  config.vm.provision :shell, :inline => <<-EOF
    cat /tmp/key >> /home/vagrant/.ssh/authorized_keys
    mkdir -p /root/.ssh
    cp /home/vagrant/.ssh/authorized_keys /root/.ssh/authorized_keys
  EOF

  host_vars = {}
  nodes.each_with_index do |name, idx|
    config.vm.define name, :autostart => true do |node|
      node.vm.hostname = name
      node.vm.synced_folder '.', '/vagrant', disabled: true

      node.vm.network :private_network,
        :ip => "192.168.17.#{10 + idx}"

      # node.vm.provider :libvirt do |domain|
      #   domain.storage :file, :size => '40G', :type => 'raw'
      #   domain.storage :file, :size => '40G', :type => 'raw'
      # end
      if idx == nodes.size - 1
        # Kick off provisioning
        node.vm.provision :ansible do |ansible|
          ansible.groups = {
            "first_node" => nodes[0],
            "first_node:vars" => {
              "kubernetes_master" => true,
              "metallb_ip_range" => "192.168.17.180/25"
            },
            "nodes" => nodes,
            "nodes:vars" => {"kubernetes_node" => true},
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
    libvirt.memory = 2000
    libvirt.cpus = `grep -c ^processor /proc/cpuinfo`.to_i
    libvirt.qemu_use_session = false
  end
end
