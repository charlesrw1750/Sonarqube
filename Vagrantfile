Vagrant.configure("2") do |config|
    config.vm.box = 'centos/7'
    config.vm.hostname = 'sonarqube'
    config.vm.network 'forwarded_port', guest: 9000, host: 9000, host_ip: '127.0.0.1'
    config.vm.provision 'shell', path: 'provision.sh'
    config.vm.provider 'virtualbox' do |v|
        v.memory =1024
    config.vbguest.installer_options = { allow_kernel_upgrade: true }
    end

end

    
