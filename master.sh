#!/bin/bash


vFile="Vagrantfile"


if [[ "$(pwd)" == "~/cloud/MS/boxes" ]]; then
	vagrant init ubuntu/focal64
else
	mkdir -p ~/cloud/MS/boxes
	cd ~/cloud/MS/boxes
	vagrant init ubuntu/focal64
fi


if [ -f "$vFile" ]; then
	echo "$vFile exist"
	sed -i '$d' Vagrantfile
else
	echo "$vFile is not in folder.\nInitiating again..."
	vagrant init ubuntu/focal64
fi


cat << EOT >> $vFile

	config.vm.provider "virtualbox" do |vb|
		vb.memory = "1024"
		vb.cpus = "2"
	end

	config.vm.define "Master" do |subconfig|
		subconfig.vm.box = "ubuntu/focal64"
		subconfig.vm.hostname = "Master"
		subconfig.vm.network "private_network", type: "dhcp"
	end

	config.vm.define "Slave" do |subconfig|
		subconfig.vm.box = "ubuntu/focal64"
		subconfig.vm.hostname = "Slave"
		subconfig.vm.network "private_network", type: "dhcp"
	end

	config.vm.provision "shell", inline: <<-SHELL
		sudo apt update && sudo apt upgrade -y
		sudo apt-get install -y avahi-daemon libnss-mdns
	SHELL

	config.vm.provision "shell", inline: <<-SHELL
		echo -e "\n"|ssh-keygen -t rsa -N ""
		sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
		sudo systemctl restart sshd
		sudo apt install sshpass -y
	SHELL
end
EOT


vagrant up


VM_STATUS=$(vagrant status --machine-readable | grep ",state," | egrep -o '([a-z_]*)$')

case "${VM_STATUS}" in
  running)
     echo "RUNNING"
    vagrant ssh vagrant@Master <<EOF
    echo "vagrant" > /home/vagrant/pass
    sshpass -f /home/vagrant/pass ssh-copy-id vagrant@Slave
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
