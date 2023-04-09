#!/bin/bash

vtext='1.00'
usetext='Simple script that updates repositories and emails apt list --upgradable
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

hostname=$( hostname )
email='root'
now=$( date )
apt update
message="$hostname $now\n\n"
[[ -f /var/run/reboot-required ]] && message+="$( cat /var/run/reboot-required )"
message+=$( grep " can be applied immediately." /var/lib/update-notifier/updates-available )
message+="\n\nUpgradeable Packages"
message+="$( apt list --upgradable )"
message+="\n\nUse the command\nsrvrup\nto upgrade packages.\nUse the command\nsrvrboot\nto reboot server."
message+="\n\nWARNING: Some of these updates may be 'phased distribution' and will be held back from an upgrade."
message+="You can do 'apt-cache policy packageName' to see phased status."
echo -e "$message" | mail -s "Upgrade Alert" $email