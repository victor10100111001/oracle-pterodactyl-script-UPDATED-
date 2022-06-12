#!/bin/bash

#colors
YELLOW='\033[1;33m'
NC='\033[0m' 
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
LRED='\033[1;31m'


echo -e "${GREEN}"
figlet -f slant "Thank's for using my script!"
echo -e "${NC}"

apt remove figlet toilet

echo -e "${GREEN}>>MAKE SURE TO CREATE A NODE AND PASTE THE CONFIGURATION HERE /etc/pterodactyl/config.yml and do wings --debug${NC}"
echo -e "${GREEN}>>FOR NODE ALLOCATION USE THE IP DOWN BELOW${NC}"
hostname -I | awk '{print $1}'

echo -e "${GREEN}INSTALLATION FINISHED!${NC}"
sleep 4 
clear
