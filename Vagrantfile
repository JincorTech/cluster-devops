# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'
Vagrant.require_version '>=2.0.0'
ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # config.ssh.username = "vagrant"
  # config.ssh.password = ""
  config.ssh.forward_agent = true

  config.vm.box      = "ubuntu/xenial64"

  # config.vm.network :forwarded_port, guest: 80, host: 8085

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox" #, mount_options: ["uid=1000", "gid=1000", "noatime", "nodiratime", "norelatime"] #, owner: "", group: ""

  config.vm.provider :virtualbox do |v|
    v.gui = false
    v.linked_clone = true
    v.memory = 1024
    v.cpus = 1
  end

  #config.vm.provision "shell", inline: "sudo apt install python -y"
  #config.vm.provision "ansible" do |ansible|
  #  ansible.playbook = "playbook-bootstrap.yml"
  #  ansible.inventory_path = "hosts"
  #  ansible.verbose = true
  #end

  (1..3).each do |i|
    config.vm.define "node#{i}", primary: true do |node|
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip: "192.168.50.#{i+1}"
      node.vm.network "private_network", ip: "192.168.33.#{i+1}"
    end
  end

end
