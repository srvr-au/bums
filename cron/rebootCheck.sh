#!/bin/bash

hostname=$( hostname )
now=$( date )
disk="/dev/vda1"
services=(sshd nginx php7.4-fpm mariadb postfix dovecot opendkim sysstat pdns unattended-upgrades ufw)
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

echo -e "$message" | mail -s "Reboot Alert" root
