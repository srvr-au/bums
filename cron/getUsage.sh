#!/bin/bash

vtext='1.00'
usetext='Runs from cron and emails disk usage
of /home and /home2'

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

message="$hostname Disk Usage Report at $now\n"
message+="\n            Total Used Free\n"
message+="Disk Space: $( df -h | grep -w / | awk '{ print $2" "$3" "$4 }' )"
message+="\n\nWeb Disk Usage /home\n"
message+=$( du -h --max-depth=2 /home )
if [[ -d /home2 ]]; then
message+="\n\nEmail Disk Usage /home2\n"
message+=$( du -h --max-depth=2 /home2 )
fi

echo -e "$message" | mail -s "$hostname Disk Usage" $email