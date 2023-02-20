#!/bin/bash

vtext='1.00'
usetext='This script gives you the option 
  to setup an Email Server Only (No web Server)
  or an Email and Web Server.
  
  The email server comprises Postfix with RBL check,
  SPF check and DKIM. Also Dovecot and Certbot.
  
  The Web Server comprises Nginx, with MariaDB and PHP.
  Certbot is also installed.
  
  You do not have the option to setup only Nginx as a web server does need a fully fledged MTA.
  '
  
read -r -d '' htext <<-EOF
-------------------------
  Usage: ${0##*/} [options]
  Version: ${vtext}
-------------------------
  [-v]  Output Script Version
  [-h]  Output Help
-------------------------
  Use: ${usetext}
EOF

while getopts 'vh' option; do
case "${option}"
in
  v) echo $vtext; exit 1;;
  h) clear; echo "$htext"; exit 1;;
esac
done

clear

if [[ ! -f bashTK ]]; then
echo 'Please run install1.sh first...'
exit
fi
if [[ $( pwd ) != '/root/bums' ]]; then
echo 'You cannot run this script from here.'
exit
fi

source bashTK
echo -e "${btkBlu}========================${btkRes}\n${btkBlu}Bash Ubuntu Management Scripts (BUMS)${btkRes}\n${btkBlu}========================${btkRes}\n"
echo -e ${usetext}

BTKheader 'Menu Options'
bmsOptions=("Email Server Only" "Email plus Web Server")
BMSsimple
BTKpause

BTKheader 'Installing Email Server'
