# -*- mode: ruby -*-
# vi: set ft=ruby :

RIAK_NODES = 1
BASEIP = 5
IP_PRE = "10.42.0."
DOMAIN = "local.lan"
VAGRANTFILE_API_VERSION = "2"

opts = []
hosts = "127.0.0.1	localhost\n"
hosts << "127.0.1.1	`hostname -f` `hostname`\n"
n = 0

(1..RIAK_NODES).each do |i|
    n = n + 1
    name = sprintf "banana%02d", n
    opts[n] = { :name => name, :hostname => "#{name}.#{DOMAIN}", :ip => "#{IP_PRE}#{BASEIP + n.to_i}" }
    hosts << "#{opts[n][:ip]}       #{opts[n][:hostname]} #{opts[n][:name]}\n"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant|

  (1..n).each do |n|
    name = opts[n][:name]
    hostname = opts[n][:hostname]
    ip   = opts[n][:ip]

    vagrant.vm.define name do |config|

      config.vm.box = "phusion/ubuntu-14.04-amd64"

      if Vagrant.has_plugin?("vagrant-cachier")
        config.cache.scope = :box
      end

      #config.vm.name = "#{name}"
      config.vm.hostname = "#{hostname}"
      config.vm.network :private_network, ip: "#{ip}"

      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "8192"]
      end

      # Fix annoying stdin is not a tty error
      config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

      # Using VMs environment to build/install puppet modules via librarian
      config.vm.provision "shell", inline: "echo \"#{hosts}\" > /etc/hosts"
      config.vm.provision "shell", inline: "apt-get install -y ruby-dev git"
      config.vm.provision "shell", inline: "gem install librarian-puppet"

      # Move special grok patterns into place
      config.vm.provision "shell", inline: "mkdir /tmp/logstash && cp /vagrant/grok_lager /tmp/logstash/"

      # /vagrant mounts on provisioned VMs have weird permissions on windows HVs
      #    so we're running puppet apply locally on the VMs
      #    this could also be put in the background to speed up deployment
      config.vm.provision "shell", inline: "rsync -rtl /vagrant/puppet /opt/ --exclude '.*'"
      config.vm.provision "shell", inline: "cd /opt/puppet && librarian-puppet install"
      config.vm.provision "shell", inline: "puppet apply -l /var/log/puppet/provision.log --modulepath=/opt/puppet/modules --verbose --debug --hiera_config /opt/puppet/hiera.yaml /opt/puppet/manifests/site.pp"

      # Toss in some data
      config.vm.provision "shell", inline: "find /vagrant/ -name 'console.log*' -exec cat {} + >> /tmp/console.log"
    end
  end
end
