#!/bin/bash

#>>Credits to Jmantz for making this script<<

#Variables Used:

#NC -no color
#GREEN -green color
#RED -red color
#YELLOW -yellow color
#MYSQL_USERNAME -username for mysql database
#MYSQL_PASSWORD -password for mysql database
#MYSQL_PANEL_NAME -name of the database panel 
#EGG_AUTHOR_EMAIL -author email for pterodactyl user
#FQDN_VAR -contains fqdn 
#FIRST_NAME -first name of the pterodactyl user
#LAST_NAME -last name of the pterodcactyl user 
#USER_NAME -username of the pterodactyl user
#USER_EMAIL -email of the pterodactyl user
#USER_PASSWORD -password of the pterodactyl user
#SERVER_IP -ip of the machine
#DOMAIN_RECORD -domain record
#EMAIL -SSL Certificate email used
#FQDN_FOR_NODE -FQDN used in the node

#Ports:

#Panel (Defaults):
#80 [Non-SSL]
#443 [SSL]
#Wings (Defaults):
#2022 [Wings SFTP]
#8080 [Wings Communication Port]
#Wings (Proxied):
#2022 [Wings SFTP]
#8443 [Wings Communication Port with CloudFlare Proxy]

#Useful notes

#This script is made for oracle ubuntu 20.04 TLS machines. Make sure ports 80,8080,443,2022,25565-25665,8443 TCP and 80,443,2022,25565-25665,8443 UDP are added in default security list's ingress rules
#The time used for the environment setup is America/New_York the cache is redis, the session is redis, the queue is redis, redis host is localhost, password is none and redis port is 6379
#For the pterodactyl user, the user made is administrator.
#PLEASE, DO NOT RUN THE SCRIPT TWICE!

#colors
YELLOW='\033[1;33m'
NC='\033[0m' 
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
LRED='\033[1;31m'

echo -e "${CYAN}Checking if machine has the right specifications..${NC}"

ARCHITECTURE=`uname -m`

if [ "${ARCHITECTURE}" == "aarch64" ]; then
    echo -e "${GREEN}aarch64 architecture detected..!${NC}";
else
    echo -e "${RED}Machine architecture is not supported..${NC}";
    echo -e "${RED}Installation Failed..${NC}";
    echo -e "Architecture is ${YELLOW}`uname -m`${NC}"
    exit 0 
fi

sleep 0.5

if [ -r /etc/os-release ]; then
        DISTRO="$(. /etc/os-release && echo "$ID")"
        DISTRO_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
fi

sleep 0.5

if [ "$DISTRO" = "ubuntu" ]; then
    echo -e "${GREEN}ubuntu distro detected..!${NC}";
else 
    echo -e "${RED}Machine distro is not supported..${NC}";
    echo -e "${RED}Installation Failed..${NC}";
    echo -e "Distro is ${YELLOW}${DISTRO}${NC}"
    exit 0 
fi

sleep 0.5

if [ "$DISTRO_VERSION" = "20.04" ]; then 
    echo -e "${GREEN}ubuntu 20.04 version detected..!${NC}";
else 
    echo -e "${RED}Distro version is not supported..${NC}";
    echo -e "${RED}Installation Failed..${NC}";
    echo -e "Version is ${YELLOW}${DISTRO_VERSION}${NC}"
    exit 0 
fi

echo -e "${CYAN}Extracting database configuration info.."
sleep 1
echo -e "${YELLOW}^What do you want your mysql username to be? preferably, use 'pterodactyl'${NC}"
read MYSQL_USERNAME

echo -e "${YELLOW}^What do you want your mysql password to be?${NC}"
read MYSQL_PASSWORD

echo -e "${YELLOW}^What do you want your mysql name to be? preferably use 'panel'${NC}"
read MYSQL_PANEL_NAME
sleep 1
echo -e "${CYAN}Extracting panel user configuration info.."
sleep 1

echo -e "${YELLOW}^What do you want your user username to be?${NC}"
read USER_NAME

echo -e "${YELLOW}^What do you want your user first name username to be?${NC}"
read FIRST_NAME

echo -e "${YELLOW}^What do you want your user last name to be?${NC}"
read LAST_NAME

echo -e "${YELLOW}^What do you want your user password to be?${NC}"
read USER_PASSWORD

echo -e "${YELLOW}^What do you want your user email to be?${NC}"
read USER_EMAIL

echo -e "${YELLOW}^What do you want your egg author email to be?${NC}"
read EGG_AUTHOR_EMAIL

echo -e "${YELLOW}^Please insert FQDN below without http(s)://${NC}"
read FQDN_VAR

echo -e "${YELLOW}^Please insert the email used for SSL Certification${NC}"
read EMAIL

    echo "Resolving DNS..."
    SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com -4)
    DOMAIN_RECORD=$(dig +short ${FQDN_VAR})
    if [ "${SERVER_IP}" != "${DOMAIN_RECORD}" ]; then
        echo ""
        echo -e "${RED}[ERROR] The ${FQDN_VAR} domain does not point to this server."
        echo -e "${Green}Please retry by re-running the script."
        exit 0
    else
        echo "No issues with the domain, moving on"
    fi
sleep 2

#IPTABLES
echo -e "${CYAN}>>CONFIGURING IP TABLES..${NC}"
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
echo -e "${GREEN}>>FINISHED IP TABLES!${NC}"

#add-apt-repository
echo -e "${CYAN}>>ADDING "add-apt-repository" COMMAND..${NC}"
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
echo -e "${GREEN}>>FINISHED ADDING "add-apt-repository" COMMAND!${NC}"

#ADDING ADDITIONAL REPOSITORIES FOR PHP, REDIS AND MARIADB
echo -e "${CYAN}>>ADDING ADDITIONAL REPOSITORIES FOR PHP, REDIS AND MARIADB..${NC}"
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository ppa:redislabs/redis -y
echo -e "${GREEN}>>FINISHED ADDING ADDITIONAL REPOSITORIES FOR PHP, REDIS AND MARIADB!${NC}"

#DOWNLOADING MARIADB REPO SETUP AND RUNNING IT
echo -e "${CYAN}>>DOWNLOADING MARIADB REPO SETUP AND RUNNING IT...${NC}"
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
echo -e "${GREEN}>>FINISHED DOWNLOADING MARIADB REPO SETUP AND RUNNING IT!${NC}"

#INSTALLING NEEDED DEPENDENCIES
echo -e "${CYAN}>>INSTALLING NEEDED DEPENDENCIES..${NC}"
apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
echo -e "${GREEN}>>FINISHED DOWNLOADING DEPENDENCIES!${NC}"
echo -e "${RED}>>WANRING! MAKE SURE TO ADD THE INGRESS RULES FOR 80,8080,443,2022,25565-25665 TCP and 80,443,2022,25565-25665 UDP FOR MINECRAFT!${NC}"
sleep 2.5

#INSTALLING COMPOSER
echo -e "${CYAN}>>INSTALLING COMPOSER..${NC}"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer 
echo -e "${GREEN}>>FINISHED INSTALLING COMPOSER!${NC}"
echo -e "${CYAN}>>CREATING NEEDED DIRECTORIES..${NC}"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
echo -e "${GREEN}>>FINISHED CREATING DIRECTORIES!${NC}"

#DOWNLOADING PANEL FILES
echo -e "${CYAN}>>DOWNLOADING PANEL FILES..${NC}"
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
echo -e "${GREEN}>>FINISHED DOWNLOADING PANEL FILES!${NC}"

#MYSQL
echo -e "${CYAN}>>MAKING MYSQL..${NC}"
mysql -u root -e "CREATE USER '$MYSQL_USERNAME'@'127.0.0.1' IDENTIFIED BY '$MYSQL_PASSWORD'"
mysql -u root -e "CREATE DATABASE $MYSQL_PANEL_NAME"
mysql -u root -e "GRANT ALL PRIVILEGES ON $MYSQL_PANEL_NAME.* TO '$MYSQL_USERNAME'@'127.0.0.1' WITH GRANT OPTION"
echo -e "${GREEN}>>FINISHED MYSQL CONFIGURATION!${NC}"

#COPYING DEFAULT ENVIRONMENT SETTINGS FILE
echo -e "${CYAN}>>COPYING DEFAULT ENVIRONMENT SETTINGS FILE...${NC}"
cp .env.example .env
echo -e "${GREEN}>>FINISHED COPYING DEFAULT ENVIRONMENT SETTINGS FILE!${NC}"

#INSTALLING CORE DEPENDANCIES
echo -e "${CYAN}>>INSTALLING CORE DEPENDANCIES...${NC}"
composer install --no-dev --optimize-autoloader --no-interaction
echo -e "${GREEN}>>FINISHED INSTALLING CORE DEPENDANCIES!${NC}"

#CREATING ENCRYPTION KEY
echo -e "${CYAN}>>CREATING ENCRYPTION KEY...${NC}"
php artisan key:generate --force
echo -e "${GREEN}>>FINISHED CREATING ENCRYPTION KEY!${NC}"

#SETTING UP ENVIRONMENTS
echo -e "${CYAN}>>SETTING UP ENVIRONMENT...${NC}"
php artisan p:environment:setup -n --author=$EGG_AUTHOR_EMAIL --url=https://$FQDN_VAR --timezone=America/New_York --cache=redis --session=redis --queue=redis --redis-host=127.0.0.1 --redis-pass= --redis-port=6379
echo -e "${GREEN}>>FINISHED SETTING UP ENVIRONMENT!${NC}"
echo -e "${CYAN}>>SETTING UP DATABASE ENVIRONMENT..${NC}"
php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=$MYSQL_PANEL_NAME --username=$MYSQL_USERNAME --password=$MYSQL_PASSWORD
echo -e "${GREEN}>>FINISHED SETTING UP DATABASE ENVIRONMENT!${NC}"
echo -e "${CYAN}>>FINISHING DATABASE SETUP..${NC}"
php artisan migrate --seed --force
echo -e "${GREEN}>>FINISHED DATABASE SETUP!${NC}"
echo -e "${CYAN}>>ADDING THE FIRST USER..${NC}"
php artisan p:user:make --email=$USER_EMAIL --admin=1 --password=$USER_PASSWORD --username=$USER_NAME --name-last=$LAST_NAME --name-first=$FIRST_NAME
echo -e "${GREEN}>>FINISHED MAKING USER!${NC}"

#SETTING UP PERMISSIONS ON PANEL FILES
echo -e "${CYAN}>>SETTING UP PERMISSIONS ON PANEL FILES (NGINX)..${NC}"
chown -R www-data:www-data /var/www/pterodactyl/*
echo -e "${GREEN}>>FINISHED FILE PERMISSIONS!${NC}"
echo -e "${CYAN}>>CONFIGURING CRONTAB..${NC}"
crontab -l | {
    cat
    echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
} | crontab -
echo -e "${GREEN}>>FINISHED CONFIGURATION!${NC}"

#CREATING QUEUE WORKER
echo -e "${CYAN}>>CREATING QUEUE WORKER..${NC}"
cd /
cd /etc/systemd/system
wget https://raw.githubusercontent.com/JmantZZ/oraclepteroinstalltionscript/main/pteroq.service
systemctl enable --now redis-server
systemctl enable --now pteroq.service
echo -e "${GREEN}>>FINISHED CREATING QUEUE WORKER!${NC}"
echo -e "${GREEN}>>ALL SYSTEMS FUNCTIONING!${NC}"

#CREATING SSL CERTIFICATES
echo -e "${CYAN}>>CREATING SSL CERTIFICATES (NGINX)..${NC}"
sudo apt update
sudo apt install -y certbot
sudo apt install -y python3-certbot-nginx
certbot certonly --nginx --email "$EMAIL" --agree-tos -d "$FQDN_VAR"
certbot renew
certbot certonly --nginx -d "$FQDN_FOR_NODE"
certbot renew
systemctl stop nginx
certbot renew
systemctl start nginx
echo -e "${GREEN}>>FINISHED CREATING SSL CERTIFICATES!${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${CYAN}PROCEEDING WITH WEBSERVER CONFIGURATION${NC}"
rm /etc/nginx/sites-enabled/default

cd /
cd /etc/nginx/sites-available/
echo '
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name '"$FQDN_VAR"';
    return 301 https://$server_name$request_uri;
}
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name '"$FQDN_VAR"';
    
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/'"$FQDN_VAR"'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'"$FQDN_VAR"'/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "0";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "upgrade-insecure-requests; block-all-mixed-content; frame-ancestors 'self'" always;
    add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), autoplay=(), battery=(), camera=(), clipboard-read=(), clipboard-write=(), display-capture=(), document-domain=(), encrypted-media=(), fullscreen=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(), publickey-credentials-get=(), screen-wake-lock=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
' | sudo -E tee /etc/nginx/sites-available/pterodactyl.conf >/dev/null 2>&1
    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    service nginx restart

echo -e "${CYAN}PROCEEDING WITH DOCKER INSTALLATION${NC}"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable --now docker
echo -e "${GREEN}>>FINISHED DOCKER INSTALLATION!${NC}"
echo -e "${CYAN}PROCEEDING WITH WING INSTALLATION${NC}"
cd /
cd /etc/default/

mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings
wget https://raw.githubusercontent.com/JmantZZ/oraclepteroinstalltionscript/main/grub
cd / 
cd /etc/systemd/system
wget https://github.com/JmantZZ/oraclepteroinstalltionscript/raw/main/wings.service
cd /
echo -e "${GREEN}>>INSTALLATION OF PANEL HAS BEEN COMPLETED. MAKE SURE TO CREATE A NODE AND PASTE THE CONFIGURATION HERE /etc/pterodactyl/config.yml and do wings --debug${NC}"
echo -e "${GREEN}>>FOR NODE ALLOCATION USE THE IP DOWN BELOW${NC}"
hostname -I | awk '{print $1}'
sleep 4 
wget https://raw.githubusercontent.com/JmantZZ/oraclepteroinstalltionscript/main/exit.sh
bash exit.sh
