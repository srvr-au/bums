#!/bin/bash

vtext='1.00'
usetext='Runs from cron after reboot and
sends email with some basic system checks.'

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

hostname=$( hostname )
email='root'
now=$( date )
disk='/dev/vda1 '
services=(ssh unattended-upgrades ufw sysstat nginx php7.4-fpm mariadb postfix dovecot opendkim pdns)
message="$hostname was rebooted at $now\n"

message+="\nMemory usage: \n"
message+="$( free -tm )"
message+="\n\nUptime: "
message+="$( uptime )"
message+="\n\nDisk Space Used: "
message+="$( df -h | grep $disk | awk '{ print $5 }' | sed 's/G//g' )"
message+="\n\nServices:\n==================\n"

for i in "${services[@]}"; do
systemctl list-unit-files | grep "$i"
if [ $? -eq 0 ]; then
if [ $( systemctl is-enabled $i ) == 'enabled' ]; then
if [ $( systemctl is-active $i ) != 'active' ]; then
message+="$i is enabled BUT NOT ACTIVE\n"
else
message+="$i is enabled and active\n"
fi
else
message+="$i is NOT ENABLED\n"
fi
else
message+="$i is NOT INSTALLED\n"
fi
done

echo -e "$message" | mail -s "Reboot Alert" $email
