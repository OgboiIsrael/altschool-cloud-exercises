#!/bin/bash

# Variable declarations
V_File="Vagrantfile"
VM_Master="master"
VM_Slave="slave"
IP_Master="192.168.16.1"
IP_Slave="192.168.16.2"
NewUser="AltSchool"
SQL_RPasswd="RootAltSchool"
SQL_dUser="AltSchool"
SQL_dUserPasswd="AltSchool"

# Create folder to host Vagrantfile
if [[ "$(pwd)" == "~/Documents/cloud/Box" ]]; then
    vagrant init ubuntu/focal64
else
    mkdir -p ~/Documents/cloud/Box
    cd ~/Documents/cloud/Box
    vagrant init ubuntu/focal64
fi

# Initialize Vagrant environment to create Vagrantfile
if [ -f "$V_File" ]; then
    echo "$V_File exists"
    sed -i '$d' Vagrantfile
else
    echo "$V_File does not exist in predefined folder."
    echo "Creating Vagrantfile..."
    vagrant init ubuntu/focal64
fi

# Adding Configs to Vagrantfile to create Master and Slave VM
cat <<EOT >> $V_File
config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
end

config.vm.define "Master" do |subconfig|
    subconfig.vm.hostname = "$VM_Master"
    subconfig.vm.network "private_network", ip: "$IP_Master"
    subconfig.vm.disk :disk, size: "10GB", primary: true
end

config.vm.define "Slave" do |subconfig|
    subconfig.vm.hostname = "$VM_Slave"
    subconfig.vm.network "private_network", type: "$IP_Slave"
    subconfig.vm.disk :disk, size: "10GB", primary: true
end

config.vm.provision "shell", inline: <<-SHELL
    # Create new user and grant root privileges
    echo "Creating new user - AltSchool and granting root privileges..."
    sudo useradd -m -G root $NewUser

    echo "Installing LAMP stack..."
    sudo apt update && sudo apt upgrade -y
    sudo apt-get install -y avahi-daemon libnss-mdns
    echo "Installing LAMP Stack..."
    sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql

    # Configure Apache2 to start on boot
    echo "Apache2 to start on boot..."
    sudo systemctl enable apache2
    sudo systemctl start apache2

    echo "Secure MySQL installation on VMs..."
    sudo mysql_secure_installation
    echo "Initializing MySQL with default user and password..."
    sudo mysql -uroot -p$SQL_RPasswd -e "CREATE USER '$SQL_dUser'@'localhost' IDENTIFIED BY '$SQL_dUserPasswd';"
    sudo mysql -uroot -p$SQL_RPasswd -e "GRANT ALL PRIVILEGES ON . TO '$SQL_dUser'@'localhost' WITH GRANT OPTION;"
    sudo mysql -uroot -p$SQL_RPasswd -e "FLUSH PRIVILEGES;"

    # Validate PHP functionality with Apache
    echo "Generating PHP test file..."
    echo -e '<?php\n\tphpinfo();\n?>' | sudo tee /var/www/html/index.php

SHELL
end
EOT

# Start the VMs
vagrant up

# Enable SSH key-based authentication to allow Master to connect to Slave without a password
echo "SSH key-based authentication to allow Master to connect to Slave without a password..."
vagrant ssh $VM_Master <<EOF
sudo su - $NewUser
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
ssh-copy-id $NewUser@$VM_Slave
sudo systemctl reload sshd
exit
exit
EOF

# Copy contents of /mnt/AltSchool from Master node to Slave
echo "Copying /mnt/AltSchool from master to slave..."
vagrant ssh $VM_Master -c "rsync -avz /mnt/AltSchool/ $NewUser@$IP_Slave:/mnt/AltSchool/slave/"

# Display overview of currently running processes on Master node
echo "Overview of currently running processes on Master:"
vagrant ssh $VM_Master -c "ps aux"

# Connect Slave to Master for management
echo "Connecting slave to master for management..."
vagrant ssh $VM_Slave <<EOF
sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
sudo systemctl enable apache2
sudo systemctl start apache2
exit
EOF

echo "Master and Slave VMs deployed successfully :)"
echo -e "$VM_Master: $IP_Master\n$VM_Slave: $IP_Slave"
