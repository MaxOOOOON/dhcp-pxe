# -*- mode: ruby -*-
# vi: set ft=ruby :
file_to_disk = './disk1.vdi'
Vagrant.configure("2") do |config|

  config.vm.define "pxeserver" do |server|
    config.vm.box = 'centos/8'
    config.vm.boot_timeout = 600
    server.vm.host_name = 'pxeserver'
    server.vm.network :private_network, 
                       ip: "10.0.0.20", 
                       virtualbox__intnet: 'pxenet'
    

    # server.vm.network "forwarded_port", guest: 80, host: 8081
  
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
  

    server.vm.provision :ansible do |ansible|
      ansible.playbook = "./playbook.yml"
      ansible.inventory_path = "./inventory.yml"
      # ansible.verbose = true
    end

    # ENABLE to setup PXE
    # server.vm.provision "shell",
    #   name: "Setup PXE server",
    #   path: "setup_pxe.sh"
    end
  
  
    config.vm.define "pxeclient" do |pxeclient|

      pxeclient.vm.host_name = 'pxeclient'
      pxeclient.vm.network :private_network, ip: "10.0.0.21"
      pxeclient.vm.provider :virtualbox do |vb|
        vb.memory = "2048"
        vb.gui = true
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize [
            'modifyvm', :id,
            '--nic1', 'intnet',
            '--intnet1', 'pxenet',
            '--nic2', 'nat',
            '--boot1', 'net',
            '--boot2', 'none',
            '--boot3', 'none',
            '--boot4', 'none'
          ]

      end
    end
  
    

  end