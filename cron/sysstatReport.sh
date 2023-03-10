#!/bin/bash

vtext='1.00'
usetext='Runs from cron and uses sadf to print graphs.
Needs sysstat installed and enabled.'

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
now=$( date )
email='root'
subject="$hostname - SysStat Report"
message="$now"
graphsDir='/root/bums/cron/graphs/'

sadf -g -T -- -r ALL -1 > ${graphsDir}memory.svg
sadf -g -T -- -P ALL -1 > ${graphsDir}cpu.svg
sadf -g -T -- -q LOAD -1 > ${graphsDir}load.svg
sadf -g -T -- -S -1 > ${graphsDir}swap.svg

echo -e "$message" | mail -s "$subject" -a ${graphsDir}memory.svg -a ${graphsDir}cpu.svg -a ${graphsDir}load.svg -a ${graphsDir}swap.svg $email
