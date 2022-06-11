#!bin/bash

#colors
YELLOW='\033[1;33m'

NC='\033[0m' 

GREEN='\033[0;32m'

RED='\033[0;31m'

echo -e "${YELLOW}>>CONFIGURING IP TABLES..${NC}"
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
echo -e "${GREEN}>>FINISHED IP TABLES!${NC}"
echo -e "${YELLOW}>>ADDING "add-apt-repository" COMMAND..${NC}"
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
echo -e "${GREEN}>>FINISHED ADDING "add-apt-repository" COMMAND!${NC}"
echo -e "${YELLOW}>>ADDING ADDITIONAL REPOSITORIES FOR PHP, REDIS AND MARIADB..${NC}"
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository ppa:redislabs/redis -y
echo -e "${GREEN}>>FINISHED ADDING ADDITIONAL REPOSITORIES FOR PHP, REDIS AND MARIADB!${NC}"
echo -e "${YELLOW}>>DOWNLOADING MARIADB REPO SETUP AND RUNNING IT...${NC}"
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
echo -e "${GREEN}>>FINISHED DOWNLOADING MARIADB REPO SETUP AND RUNNING IT!${NC}"
echo -e "${YELLOW}>>INSTALLING NEEDED DEPENDENCIES..${NC}"
apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
echo -e "${GREEN}>>FINISHED DOWNLOADING DEPENDENCIES!${NC}"
echo -e "${RED}>>WANRING! MAKE SURE TO ADD THE INGRESS RULES FOR 80,8080,443,2022,25565-25665 TCP and 80,443,2022,25565-25665 UDP FOR MINECRAFT!${NC}"
echo -e "${YELLOW}>>INSTALLING COMPOSER..${NC}"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer 
echo -e "${GREEN}>>FINISHED INSTALLING COMPOSER!${NC}"
echo -e "${YELLOW}>>CREATING NEEDED DIRECTORIES..${NC}"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
echo -e "${GREEN}>>FINISHED CREATING DIRECTORIES!${NC}"
echo -e "${YELLOW}>>DOWNLOADING PANEL FILES..${NC}"
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
echo -e "${GREEN}>>FINISHED DOWNLOADING PANEL FILES!${NC}"
echo -e "${YELLOW}>>CONFIGURING MYSQL..${NC}"
echo -e "${YELLOW}^What do you want your username to be? (pterodactyl)${NC}"
read MYSQL_USERNAME
echo -e "${YELLOW}^What do you want your password to be?${NC}"
read MYSQL_PASSWORD
echo -e "${YELLOW}^What do you want your panel name to be?(panel)${NC}"
read MYSQL_PANEL_NAME
mysql -u root -e "CREATE USER '$MYSQL_USERNAME'@'127.0.0.1' IDENTIFIED BY '$MYSQL_PASSWORD'"
mysql -u root -e "CREATE DATABASE $MYSQL_PANEL_NAME"
mysql -u root -e "GRANT ALL PRIVILEGES ON $MYSQL_PANEL_NAME.* TO '$MYSQL_USERNAME'@'127.0.0.1' WITH GRANT OPTION"
echo -e "${GREEN}>>FINISHED MYSQL CONFIGURATION!${NC}"
echo -e "${YELLOW}>>COPYING DEFAULT ENVIRONMENT SETTINGS FILE...${NC}"
cp .env.example .env
echo -e "${GREEN}>>FINISHED COPYING DEFAULT ENVIRONMENT SETTINGS FILE!${NC}"
echo -e "${YELLOW}>>INSTALLING CORE DEPENDANCIES...${NC}"
composer install --no-dev --optimize-autoloader
echo -e "${GREEN}>>FINISHED INSTALLING CORE DEPENDANCIES!${NC}"
echo -e "${YELLOW}>>CREATING ENCRYPTION KEY...${NC}"
php artisan key:generate --force
echo -e "${GREEN}>>FINISHED CREATING ENCRYPTION KEY!${NC}"
echo -e "${YELLOW}>>SETTING UP ENVIRONMENT...${NC}"
echo -e "${YELLOW}^What do you want your egg author email to be?${NC}"
read EGG_AUTHOR_EMAIL
echo -e "${YELLOW}^Please insert FQDN below without http(s)://${NC}"
read FQDN_VAR
php artisan p:environment:setup -n --author=$EGG_AUTHOR_EMAIL --url=https://$FQDN_VAR --timezone=America/New_York --cache=redis --session=redis --queue=redis --redis-host=127.0.0.1 --redis-pass= --redis-port=6379
echo -e "${GREEN}>>FINISHED SETTING UP ENVIRONMENT!${NC}"
echo -e "${YELLOW}>>SETTING UP DATABASE ENVIRONMENT..${NC}"
php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=$MYSQL_PANEL_NAME --username=$MYSQL_USERNAME --password=$MYSQL_PASSWORD
echo -e "${GREEN}>>FINISHED SETTING UP DATABASE ENVIRONMENT!${NC}"
echo -e "${YELLOW}>>FINISHING DATABASE SETUP..${NC}"
php artisan migrate --seed --force
echo -e "${GREEN}>>FINISHED DATABASE SETUP!${NC}"
echo -e "${YELLOW}>>ADDING THE FIRST USER..${NC}"
echo -e "${YELLOW}What do you want the email of the user to be?${NC}"
read USER_EMAIL
echo -e "${YELLOW}What do you want the password of the user to be?${NC}"
read USER_PASSWORD
echo -e "${YELLOW}What do you want the username of the user to be?${NC}"
read USER_NAME
php artisan p:user:make --email=$USER_EMAIL --admin=1 --password=$USER_PASSWORD --username=$USER_NAME
echo -e "${GREEN}>>FINISHED MAKING USER!${NC}"
echo -e "${YELLOW}>>SETTING UP PERMISSIONS ON PANEL FILES (NGINX)..${NC}"
chown -R www-data:www-data /var/www/pterodactyl/*
echo -e "${GREEN}>>FINISHED FILE PERMISSIONS!${NC}"
echo -e "${YELLOW}>>CONFIGURING CRONTAB..${NC}"
crontab -l | {
    cat
    echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
} | crontab -
echo -e "${GREEN}>>FINISHED CONFIGURATION!${NC}"
echo -e "${YELLOW}>>CREATING QUEUE WORKER..${NC}"
cd /
cd /etc/systemd/system
wget https://raw.githubusercontent.com/JmantZZ/shellscripttest/main/pteroq.service
systemctl enable --now redis-server
systemctl enable --now pteroq.service

echo -e "${GREEN}>>FINISHED CREATING QUEUE WORKER!${NC}"
echo -e "${GREEN}>>ALL SYSTEMS FUNCTIONING!${NC}"
echo -e "${YELLOW}>>CREATING SSL CERTIFICATES (NGINX)..${NC}"
sudo apt update
sudo apt install -y certbot
sudo apt install -y python3-certbot-nginx
certbot certonly --nginx -d $FQDN_VAR
certbot renew
systemctl stop nginx
certbot renew
systemctl start nginx
echo -e "${GREEN}>>FINISHED CREATING SSL CERTIFICATES!${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${RED}>>MAKE SURE INGRESS RULES/FIREWAL HAVE BEEN PROPERLY MADE AND THE FQDN POINTS AT THE RIGHT ADDRESS${NC}"
echo -e "${YELLOW}PROCEEDING WITH WEBSERVER CONFIGURATION${NC}"
rm /etc/nginx/sites-enabled/default

echo -e "${YELLOW}Are ingress rules/firewall and the fqdn done? (yes) - (no)${NC}"
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
echo -e "${YELLOW}PROCEEDING WITH DOCKER INSTALLATION${NC}"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable --now docker
echo -e "${GREEN}>>FINISHED DOCKER INSTALLATION!${NC}"
echo -e "${YELLOW}PROCEEDING WITH WING INSTALLATION${NC}"
cd /
cd /etc/default/
wget https://raw.githubusercontent.com/JmantZZ/shellscripttest/main/grub
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings

echo -e "${GREEN}>>INSTALLATION OF PANEL HAS BEEN ${NC}"
cd / 
wget /etc/systemd/system https://raw.githubusercontent.com/JmantZZ/shellscripttest/main/wings.service
echo -e "${GREEN}>>INSTALLATION OF PANEL HAS BEEN COMPLETED. MAKE SURE TO CREATE A NODE AND PASTE THE CONFIGURATION HERE /etc/pterodactyl/config.yml and do wings --debug${NC}"
echo -e "${GREEN}>>FOR NODE ALLOCATION USE THE IP DOWN BELOW${NC}"
hostname -I | awk '{print $1}'