#!/bin/bash

# Set the variables for VM names and IP addresses
MASTER_VM="master"
SLAVE_VM="slave"
MASTER_IP="192.168.33.10"
SLAVE_IP="192.168.33.11"
NEW_USER="AltSchool" # AltSchool User Created
MYSQL_ROOT_PASSWORD="Alt-school"
MYSQL_ALT_USER="AltSchooler"
MYSQL_ALT_PASSWORD="Alt.schooler"

# Initialize Vagrant environment
vagrant init ubuntu/focal64

# Create the Master VM
vagrant up $MASTER_VM --provider virtualbox

# Create the Slave VM
vagrant up $SLAVE_VM --provider virtualbox

# Install LAMP stack on Master
echo "Installing LAMP stack on Master..."
vagrant ssh $MASTER_VM -c "sudo apt update"
vagrant ssh $MASTER_VM -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Create user AltSchool on Master
echo "Creating user AltSchool on Master..."
vagrant ssh $MASTER_VM -c "sudo adduser $NEW_USER"

# Grant AltSchool user root (superuser) privileges
echo "Granting superuser privileges to AltSchool..."
vagrant ssh $MASTER_VM -c "sudo usermod -aG sudo $NEW_USER"

# Secure MySQL installation on Master
echo "Securing MySQL installation on Master..."
vagrant ssh $MASTER_VM -c "sudo mysql_secure_installation"

# Initialize MySQL on Master with default user and password
echo "Initializing MySQL on Master with default user and password..."
vagrant ssh $MASTER_VM -c "sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"CREATE USER '$MYSQL_ALT_USER'@'localhost' IDENTIFIED BY '$MYSQL_ALT_PASSWORD';\""
vagrant ssh $MASTER_VM -c "sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"GRANT ALL PRIVILEGES ON . TO '$MYSQL_ALT_USER'@'localhost' WITH GRANT OPTION;\""
vagrant ssh $MASTER_VM -c "sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"FLUSH PRIVILEGES;\""

# Create a PHP script on Master to test PHP functionality
echo "Creating PHP test script on Master..."
vagrant ssh $MASTER_VM -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/phpinfo.php"


# Configure Master as control system
echo "Configuring Master as control system..."
vagrant ssh $MASTER_VM -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/index.php"
vagrant ssh $MASTER_VM -c "sudo systemctl enable apache2"
vagrant ssh $MASTER_VM -c "sudo systemctl start apache2"

# Configure Apache to start on boot and start it
echo "Configuring Apache on Master..."
vagrant ssh $MASTER_VM -c "sudo systemctl enable apache2"
vagrant ssh $MASTER_VM -c "sudo systemctl start apache2"

# Install LAMP stack on Slave
echo "Installing LAMP stack on Slave..."
vagrant ssh $SLAVE_VM -c "sudo apt update"
vagrant ssh $SLAVE_VM -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Create user AltSchool on Slave
echo "Creating user AltSchool on Slave..."
vagrant ssh $SLAVE_VM -c "sudo adduser $NEW_USER"

# Grant AltSchool user root (superuser) privileges on Slave
echo "Granting superuser privileges to AltSchool on Slave..."
vagrant ssh $SLAVE_VM -c "sudo usermod -aG sudo $NEW_USER"

# Secure MySQL installation on Slave
echo "Securing MySQL installation on Slave..."
vagrant ssh $SLAVE_VM -c "sudo mysql_secure_installation"

# Initialize MySQL on Slave with default user and password
echo "Initializing MySQL on Slave with default user and password..."
vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"CREATE USER '$MYSQL_ALT_USER'@'localhost' IDENTIFIED BY '$MYSQL_ALT_PASSWORD';\""
vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"GRANT ALL PRIVILEGES ON . TO '$MYSQL_ALT_USER'@'localhost' WITH GRANT OPTION;\""
vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"FLUSH PRIVILEGES;\""

# Create a PHP script on Slave to test PHP functionality
echo "Creating PHP test script on Slave..."
vagrant ssh $SLAVE_VM -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/phpinfo.php"


# Configure Apache to start on boot and start it
echo "Configuring Apache on Slave..."
vagrant ssh $SLAVE_VM -c "sudo systemctl enable apache2"
vagrant ssh $SLAVE_VM -c "sudo systemctl start apache2"

# Configure SSH key-based authentication from Master to Slave
echo "Configuring SSH key-based authentication from Master to Slave..."
vagrant ssh $MASTER_VM -c "sudo su - $NEW_USER -c 'ssh-keygen -t rsa -b 2048 -N \"\" -f ~/.ssh/id_rsa'"
vagrant ssh $MASTER_VM -c "sudo su - $NEW_USER -c 'ssh-copy-id $NEW_USER@$SLAVE_IP'"

# Copy contents of /mnt/AltSchool from Master to Slave
echo "Copying contents from Master to Slave..."
vagrant ssh $MASTER_VM -c "sudo su - $NEW_USER -c 'rsync -avz /mnt/AltSchool/ $NEW_USER@$SLAVE_IP:/mnt/AltSchool/slave/'"

# Display overview of currently running processes on Master
echo "Overview of currently running processes on Master:"
vagrant ssh $MASTER_VM -c "ps aux"


# Connect Slave to Master for management
echo "Connecting Slave to Master for management..."
vagrant ssh $SLAVE_VM -c "sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf"
vagrant ssh $SLAVE_VM -c "sudo systemctl enable apache2"
vagrant ssh $SLAVE_VM -c "sudo systemctl start apache2"

# Configure MySQL replication (Optional - Uncomment if needed)
# echo "Configuring MySQL replication..."
# vagrant ssh $MASTER_VM -c "mysql -uroot -e 'CREATE USER \"slave\"@\"$SLAVE_IP\" IDENTIFIED BY \"password\";'"
# vagrant ssh $MASTER_VM -c "mysql -uroot -e 'GRANT REPLICATION SLAVE ON . TO \"slave\"@\"$SLAVE_IP\";'"
# vagrant ssh $MASTER_VM -c "mysql -uroot -e 'FLUSH PRIVILEGES;'"
# vagrant ssh $MASTER_VM -c "sudo sed -i 's/#server-id.*/server-id = 1/' /etc/mysql/mysql.conf.d/mysqld.cnf"
# vagrant ssh $MASTER_VM -c "sudo systemctl restart mysql"

# Ensure that Slave can connect to Master for replication (Optional - Uncomment if needed)
# vagrant ssh $SLAVE_VM -c "sudo sed -i 's/#server-id.*/server-id = 2/' /etc/mysql/mysql.conf.d/mysqld.cnf"
# vagrant ssh $SLAVE_VM -c "sudo systemctl restart mysql"
# vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -e 'CHANGE MASTER TO MASTER_HOST=\"$MASTER_IP\", MASTER_USER=\"slave\", MASTER_PASSWORD=\"password\", MASTER_LOG_FILE=\"mysql-bin.000001\", MASTER_LOG_POS=0;'"
# vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -e 'START SLAVE;'"

echo "Deployment completed successfully."
echo "Master IP: $MASTER_IP"
echo "Slave IP: $SLAVE_IP"