#!/bin/bash

# Variable declarations
NewUser="altschool"
PassWD="altpass"
DB_NAME="LaravelDB"
DB_USER="altschool"
SQL_dUserPasswd="altschool"
APP_DIR="/var/www/html/laravel"
MY_DOMAIN_NAME="pariwo.ng"
ADMIN_EMAIL="israel.imoleoluwa.kemi@gmail.com"
LARAVEL_APP="https://github.com/laravel/laravel.git"

# Provisioning scripts
# Script to install ssh and LAMP stack
sudo apt-get update && sudo apt upgrade -y
sudo apt-get install sshpass -y
sudo apt-get install -y avahi-daemon libnss-mdns
echo "Installing LAMP Stack..."
sudo apt-get install -y apache2 mysql-server

# Configure Apache2 to start on boot
echo "Apache2 to start on boot..."
sudo systemctl enable apache2
sudo systemctl start apache2

sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$SQL_dUserPasswd';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
sudo mysql_secure_installation <<EOF
$SQL_dUserPasswd
n
y
y
y
y
EOF

sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt-get install libapache2-mod-php php php-common php-xml php-mysql php-gd php-mbstring php-tokenizer php-json php-bcmath php-curl php-zip unzip -y

# Validate PHP functionality with Apache
echo "Generating PHP test file..."
echo -e '<?php\n\tphpinfo();\n?>' | sudo tee /var/www/html/index.php

# Clone Laravel PHP project from Github
# Installing prerequisites for Laravel
sudo apt-get update
sudo apt-get install git composer -y

# Configure Apache to host laravel application
cat <<EOL | sudo tee /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
    ServerAdmin $ADMIN_EMAIL
    DocumentRoot $APP_DIR/public
    ServerName $MY_DOMAIN_NAME

    <Directory $APP_DIR/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

sudo a2enmod rewrite
sudo a2ensite laravel.conf
sudo systemctl restart apache2

# Install Laravel Application from GitHub
cd /var/www/html
git clone $LARAVEL_APP
cd /var/www/html/laravel && composer install --no-dev

# Setting Laravel Permission for Apache 
sudo chown -R www-data:www-data /var/www/html/laravel
sudo chmod -R 775 /var/www/html/laravel
sudo chmod -R 775 /var/www/html/laravel/storage
sudo chmod -R 775 /var/www/html/laravel/bootstrap/cache

# Create the database
mysql -u root -p -e "CREATE DATABASE $DB_NAME;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -p -e "FLUSH PRIVILEGES;"

# Edit details in the .env fle
cd /var/www/html/laravel
cp .env.example .env
php artisan key:generate

sudo sed -i "s/APP_URL=/APP_URL=https://$MY_DOMAIN_NAME/" /var/www/html/laravel/.env
sudo sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/" /var/www/html/laravel/.env
sudo sed -i "s/DB_USERNAME=root/DB_PASSWORD=$DB_USER/" /var/www/html/laravel/.env
sudo sed -i "s/DB_PASSWORD=/DB_PASSWORD=$SQL_dUserPasswd/" /var/www/html/laravel/.env

php artisan config:cache

cd /var/www/html/laravel && php artisan migrate