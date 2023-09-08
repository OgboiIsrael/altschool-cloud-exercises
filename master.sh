#!/bin/bash

# variables
File="vagrantfile"
count=$(wc -l < vagrantfile)


# DIRECTORY TO PULL FILE

if [[ "$PWD" == "~/Documents/vagrant/master" ]]; then
  vagrant init ubuntu/focal64
else
  mkdir -p ~/Documents/vagrant/master
  cd ~/Documents/vagrant/master
  vagrant init ubuntu/focal64
fi


 # DELETING LAST LINE

if [ -f "$File" ]; then  
    echo "$File exist"
    sed -i '$ d' vagrantfile
else  
    echo "$File does not exist"  
    echo "pulling file again.."
    vagrant init ubuntu/focal64
fi  

 

# INPUT CODE TO VAGRANTFILE


# setting disk usage
    cat << EOT >> $File

    config.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "2"
    end
EOT


# running master
    cat << EOT >> $File

    config.vm.define "master" do |subconfig|
      subconfig.vm.box = "ubuntu/focal64"
      subconfig.vm.hostname = "master"
      subconfig.vm.network "private_network", type: "dhcp"
    end
EOT


# running slave
    cat << EOT >> $File

    config.vm.define "slave" do |subconfig|
      subconfig.vm.box = "ubuntu/focal64"
      subconfig.vm.hostname = "slave"
      subconfig.vm.network "private_network", type: "dhcp"
    end
EOT

# PROVISIONING SCRIPT TO VAGRANT FILE

# installing dns
    cat << EOT >> $File

    config.vm.provision "shell", inline: <<-SHELL
      sudo apt update && sudo apt upgrade -y
      sudo apt-get install -y avahi-daemon libnss-mdns
    SHELL
EOT



# SSH-KEY, SSHD SETTINGS
cat << EOT >> $File

    config.vm.provision "shell", inline: <<-SHELL
      #CREATE SSH-KEY
        echo -e "\n"|ssh-keygen -t rsa -N ""
      #CHANGE SETTINGS IN SSHD
        sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sudo systemctl restart sshd
        sudo apt install sshpass -y
    SHELL
end
EOT



vagrant up


#CREATE ALTSCHOOL MASTER USER & COPY MNT DIR TO SLAVE & INSTALL SSHPASS & RUN SSH-COPY-ID

VM_STATUS=$(vagrant status --machine-readable | grep ",state," | egrep -o '([a-z_]*)$')

case "${VM_STATUS}" in
  running)
     echo "RUNNING"
    vagrant ssh vagrant@master <<EOF
    echo "vagrant" > /home/vagrant/pass
    sshpass -f /home/vagrant/pass ssh-copy-id vagrant@slave
    sudo useradd -m -G root altschool
    sudo scp -r /mnt/altschool vagrant@Slave:/mnt/altschool
    sudo ps aux > /home/vagrant/running_process
EOF
  ;;
  poweroff)
     echo "POWEROFF"
     vagrant up
  ;;
  *)
     echo "Unhandled: ${VM_STATUS}"
  ;;
esac