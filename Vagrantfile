Vagrant.configure("2") do |config|
  config.vm.box = "generic/rocky9"
  config.vm.hostname = "k3s-vm"
  config.vm.network "private_network", ip: "192.168.121.10", libvirt__network_name: "default"


  config.vm.provider :libvirt do |lv|
    lv.memory = 4096
    lv.cpus = 2
    lv.graphics_type = "none"   # headless
    lv.disk_bus = "virtio"
    lv.nic_model_type = "virtio"
  end

  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".git/"]

  config.vm.provision "file", source: "bootstrap-k3s-flux-traefik.sh", destination: "/home/vagrant/bootstrap-k3s-flux-traefik.sh"
  config.vm.provision "file", source: ".env", destination: "/home/vagrant/.env"
  config.vm.provision "shell", inline: <<-SHELL
    sudo dnf install -y git
    chown vagrant:vagrant /home/vagrant/bootstrap-k3s-flux-traefik.sh
    chmod +x /home/vagrant/bootstrap-k3s-flux-traefik.sh
    echo "Bootstrap script is ready. SSH in as vagrant and run 'source .env && ./bootstrap-k3s-flux-traefik.sh'"
  SHELL
end
