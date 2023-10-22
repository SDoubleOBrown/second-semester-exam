#!/bin/bash

################################################################
#UPDATE AND INSTALL PACKAGES
################################################################

sudo apt update -y

sudo apt upgrade -y

#################################################################
#INSTALL APACHE
#################################################################

sudo apt install apache2 -y < /dev/null

sudo systemctl start apache2

sudo systemctl enable apache2

##################################################################
#INSTALL MySQL
##################################################################

sudo apt install mysql-server < /dev/null

sudo systemctl start mysql

sudo systemctl enable mysql

##################################################################
#INSTALL PHP
##################################################################

sudo apt-get install lsb-release ca-certificates apt-transport-https software-properties-common -y < /dev/null

sudo add-apt-repository ppa:ondrej/php -y < /dev/null

sudo apt-get install php8.0 -y < /dev/null

sudo apt install libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-common php-tokenizer php-json php-bcmath php-zip unzip -y < /dev/null

sudo systemctl reload apache2

####################################################################
#INSTALL COMPOSER
####################################################################

sudo apt install curl -y < /dev/null

curl -sS https://getcomposer.org/installer | php < /dev/null

if [ -f composer.phar ]; then
    # Move Composer to the correct location
    sudo chmod +x /usr/local/bin/composer
    sudo mv composer.phar /usr/local/bin/composer
    composer --version
else
    echo "Composer installation failed. Please check your internet connection and try again."
    exit 1
fi

#######################################################################
#INSTALL LARAVEL AND DEPENDECIES
#######################################################################

cd /var/www/html && sudo git clone https://github.com/laravel/laravel.git

cd /var/www/html/laravel && composer install --no-dev < /dev/null

sudo chown -R www-data:www-data /var/www/html/laravel

sudo chmod -R 775 /var/www/html/laravel

sudo chmod -R 775 /var/www/html/laravel/storage

sudo chmod -R 775 /var/www/html/laravel/bootstrap/cache

cd /var/www/html/laravel && sudo cp .env.example .env

php artisan key:generate

######################################################################
#CONFIGURE APACHE FOR LARAVEL
######################################################################

cat <<EOF > /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>

    ServerAdmin derinbrown66@gmail.com
    ServerName 192.168.20.11
    DocumentRoot /var/www/html/laravel/public

    <Directory /var/www/html/laravel>
      Options Indexes Multiviews FollowSymlinks
      AllowOverride All
      Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

######################################################################
#ACTIVATE REWRITE MODULE
######################################################################

sudo a2enmod rewrite

sudo a2ensite laravel.conf

sudo systemctl restart apache2

#####################################################################
#CONFIGURE MySQL
#####################################################################

PASS=$2

if [ -z "$2" ]; then
  PASS=`openssl rand -base64 8`
fi

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $1;
CREATE USER '$1'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON $1.* TO '$1'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "MySQL user and database created."
echo "Username: $1"
echo "Database: $1"
echo "Password: $PASS"

######################################################################
#EXECUTE KEY GENERATION
######################################################################

sudo sed -i 's/DB_DATABASE=laravel/DB_DATABASE=altschool/' /var/www/html/laravel/.env

sudo sed -i 's/DB_USERNAME=root/DB_USERNAME=altschool/' /var/www/html/laravel/.env

sudo sed -i 's/DB_PASSWORD=/DB_PASSWORD=altschool001/' /var/www/html/laravel/.env

php artisan config:cache

cd /var/www/html/laravel && php artisan migrate

######################################################################
#INSTALL ANSIBLE
#####################################################################

sudo apt install ansible -y < /dev/null

#####################################################################