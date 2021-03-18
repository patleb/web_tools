# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = 'bento/ubuntu-20.04'
  # config.vm.box = 'web_tools'
  # config.vm.box_version = '0'

  config.ssh.forward_agent = true
  # config.ssh.password = "vagrant"

  if Vagrant.has_plugin? 'vagrant-hostmanager'
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
  end

  hostname, ip, public_key = 'vagrant-web.test', '192.168.65.34', `ssh-keygen -f .vagrant/private_key -y`.strip
  subdomains = [
  ]
  link_dev = false
  link_paths = [
    # '~/Desktop/tools/web_tools',
  ]

  config.vm.define :web, primary: true do |node|
    node.vm.hostname = hostname
    node.vm.network :private_network, ip: ip
    node.vm.provider :virtualbox do |vb|
      # vb.memory = '768'
      vb.memory = '1024'
      # vb.memory = '2048'
      vb.name = 'web_tools'
      vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    end
    node.vm.provision :shell do |server|
      server.inline = "grep -Fq '#{public_key}' || echo '#{public_key}' >> /home/vagrant/.ssh/authorized_keys"
    end
    node.trigger.before :up do |trigger|
      trigger.run = { inline: "cp -f .vagrant/private_key .vagrant/machines/web/virtualbox/private_key" }
    end
    node.trigger.after :up do |trigger|
      # trigger.run_remote = { inline: 'sudo service ntp stop; sudo ntpd -gq; sudo service ntp start' }
    end
    if Vagrant.has_plugin?('vagrant-hostmanager') && subdomains.any?
      node.hostmanager.aliases = subdomains.map do |subdomain|
        "#{subdomain}.#{hostname}"
      end
    end
    if link_dev
      node.vm.synced_folder './', '/vagrant', owner: 'deployer', group: 'deployer'
      # node.vm.synced_folder './tmp/shared_data', '/opt/shared_data', owner: 'deployer', group: 'deployer' # cluster
      # node.vm.synced_folder './tmp/shared_data', '/mnt/shared_data', owner: 'deployer', group: 'deployer' # master
      link_paths.each do |root|
        if (dir = Pathname.new(root).expand_path).exist?
          user = dir.to_s.match(/home\/(\w+)\//)[1]
          node.vm.synced_folder dir.to_s, dir.to_s.sub("/home/#{user}/", '/home/deployer/')
        end
      end
    end
  end

  # [1, 2].each do |i|
  [].each do |i|
    config.vm.define "compute-#{i}" do |node|
      node.vm.network :private_network, ip: "#{ip[0..-2]}#{ip[-1].to_i + i}"
      node.vm.provider :virtualbox do |vb|
        # vb.memory = '768'
        vb.memory = '1024'
        # vb.memory = '2048'
        vb.name = "web_tools-compute-#{i}"
        vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      end
      node.vm.provision :shell do |server|
        server.inline = "grep -Fq '#{public_key}' || echo '#{public_key}' >> /home/vagrant/.ssh/authorized_keys"
      end
      node.trigger.before :up do |trigger|
        trigger.run = { inline: "cp -f .vagrant/private_key .vagrant/machines/compute-#{i}/virtualbox/private_key" }
      end
      node.trigger.after :up do |trigger|
        # trigger.run_remote = { inline: 'sudo service ntp stop; sudo ntpd -gq; sudo service ntp start' }
      end
      if link_dev == :all
        node.vm.synced_folder './', '/vagrant', owner: 'deployer', group: 'deployer'
        link_paths.each do |root|
          if (dir = Pathname.new(root).expand_path).exist?
            user = dir.to_s.match(/home\/(\w+)\//)[1]
            node.vm.synced_folder dir.to_s, dir.to_s.sub("/home/#{user}/", '/home/deployer/')
          end
        end
      end
    end
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
