# -*- mode: ruby -*-
# vi: set ft=ruby :


def recommended_node_ram(num_nodes)
  free_ram = %x(free -m).split(" ")[9].to_i
  max_allowed = (free_ram * 0.9).to_i
  if num_nodes == 1
    return 4000 if 4000 < max_allowed else max_allowed
  end

  return 2000 if num_nodes * 2000 < max_allowed
  return (max_allowed / num_nodes).to_i
end

Vagrant.configure("2") do |config|

  nodes = (1..(ENV["NUM_NODES"]||1).to_i).map {|i| "node#{i}.example.org"}
  verbosity = ENV["VERBOSITY"]||""
  playbook = ENV["PLAYBOOK"]||"playbooks/deploy.yml"
  node_ram = (ENV["NODE_RAM"]||recommended_node_ram(nodes.length())).to_i
  puts "Allocating #{node_ram}MiB RAM to each node in the cluster"

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

      if idx == 0
        # Configure NFS on master to test out backups
        config.vm.provision :shell, :inline => <<-EOF
          yum install -y nfs-utils
          mkdir -p /export/backup
          chmod -R 777 /export
          chown nfsnobody:nfsnobody /export

          systemctl enable rpcbind
          systemctl enable nfs-server
          systemctl enable nfs-lock
          systemctl enable nfs-idmap
          systemctl start rpcbind
          systemctl start nfs-server
          systemctl start nfs-lock
          systemctl start nfs-idmap

          echo "/export    $(ip addr show eth1 | grep 'inet ' | awk '{printf $2}' | awk -F '/' '{print $1}')(rw,sync,no_root_squash,no_all_squash)" > /etc/exports

          systemctl restart nfs-server
        EOF
      end

      node.vm.network :private_network,
        :ip => "192.168.17.#{10 + idx}",
        :libvirt__dhcp_enabled => false

      node.vm.provider :libvirt do |domain|
        domain.storage :file, :size => '10G', :type => 'raw'
        domain.storage :file, :size => '10G', :type => 'raw' if nodes.length() < 3
        domain.storage :file, :size => '10G', :type => 'raw' if nodes.length() < 2
      end
      if idx == nodes.size - 1
        # Kick off provisioning
        node.vm.provision :ansible do |ansible|
          ansible.groups = {
            "first_node" => nodes[0],
            "first_node:vars" => {
              "kubernetes_master" => true,
              "metallb_ip_range" => "192.168.17.100-192.168.17.200",
              "storage_data_replicas" => 3,
              "storage_metadata_replicas" => 3,
              "nfs_backup_share_path": "/export/backup",
              "nfs_backup_server": "node1.example.org",
            },
            "nodes" => nodes,
            "nodes:vars" => {"kubernetes_node" => true},
          }
          ansible.verbose = verbosity
          ansible.playbook = playbook
          ansible.become = true
          ansible.force_remote_user = false
          ansible.limit = 'all,localhost'
          ansible.raw_ssh_args = ["-o IdentityFile=~/.ssh/id_rsa"]
          ansible.host_vars = host_vars
          ansible.extra_vars = 'config.yml'
        end
      end
    end
  end


  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = node_ram
    libvirt.cpus = `grep -c ^processor /proc/cpuinfo`.to_i
    libvirt.qemu_use_session = false
  end
end
