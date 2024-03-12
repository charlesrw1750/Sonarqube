Vagrant.configure("2") do |config|
    config.vm.box = "centos/7"
    config.vm.hostname = "sonarqube"
    config.vbguest.installer_options = { allow_kernel_upgrade: true }
    config.vm.network "forwarded_port", guest: 9000, host: 9000, hostip: '127.0.0.1'
    config.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
    end
    config.vm.provision "shell", path: "provision.sh"

  end