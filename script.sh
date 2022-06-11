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

sudo apt install figlet toilet 
echo -e "${GREEN}"
figlet -f slant "JmantZ's Script"
echo -e "${NC}"

echo -e "${YELLOW}Make sure to add 80,8080,443,2022,25565-25665,8443 TCP and  80,443,2022,25565-25665,8443 UDP are added in default security list's ingress rules ${NC}"
echo ''
echo -e "${YELLOW}Server files are located in ${CYAN}/var/lib/pterodactyl/volumes/"
echo ''
echo -e "${YELLOW}Command for panel logs: ${CYAN}tail -n 100 /var/www/pterodactyl/storage/logs/laravel-$(date +%F).log | nc bin.ptdl.co 99${NC}"
echo ''
echo -e "${YELLOW}Command for wings logs: ${CYAN}tail -n 100 /var/log/pterodactyl/wings.log | nc bin.ptdl.co 99${NC}"
echo ''
echo -e "${YELLOW}Command for wings diagnostics:${CYAN} wings diagnostics${NC}"
echo ''
echo -e "${YELLOW}Path of Server Backups:${CYAN} /var/lib/pterodactyl/backups/${NC}"
echo ''
echo -e "${YELLOW}Wing config:${CYAN} /etc/pterodactyl/config.yml${NC}"
echo ''

echo -e "${YELLOW}Proceed with installation? (yes) or (no)${NC}"
read INSTALLATION_BOOLEAN
if [ "$INSTALLATION_BOOLEAN" = "yes" ]
then 
clear
echo -e "${YELLOW}Proceeding with installation..${NC}";
wget https://raw.githubusercontent.com/JmantZZ/oraclepteroinstalltionscript/main/panel-installer.sh
bash panel-installer.sh
else 
echo -e "${LRED}Installation failed.${NC}"
fi


