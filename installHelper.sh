#!/bin/bash

vtext='1.00'
usetext='This script should not be executed.'

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

source bashTK

if BTKisInstalled 'logwatch'; then
  BTKheader 'Configure Logwatch'
  mkdir /var/cache/logwatch
  echo 'Output = mail
Format = text
MailTo = root
Range = yesterday
Detail = low
Service = All
' > /etc/logwatch/conf/logwatch.conf
fi
BTKcmdCheck 'logwatch configured...'
BTKpause

BTKheader 'Configure Unattended Upgrades.'
echo 'Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "always";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

BTKcmdCheck 'Enable unattended upgrades to send mail and not reboot'
BTKpause

BTKheader 'Install cron files and jobs...'
mkdir /root/bums/cron
BTKcmdCheck 'Make cron Directory.'

if BTKisInstalled 'sysstat'; then
  BTKinfo 'Downloading sysstatReport.sh...'
  if wget https://raw.githubusercontent.com/srvr-au/bums/main/cron/sysstatReport.sh &&
    wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/sysstatReport.sig &&
    gpg --verify sysstatReport.sig sysstatReport.sh; then
    rm sysstatReport.sig
    BTKsuccess 'sysstatReport.sh downloaded and verified...'
    mkdir /root/bums/cron/graphs
    mv sysstatReport.sh cron/sysstatReport.sh
    BTKcmdCheck 'Move sysstatReport.sh to cron directory.'
    chmod +x cron/sysstatReport.sh
    BTKcmdCheck 'chmod sysstatReport.sh executable.'
    command="/root/bums/cron/sysstatReport.sh > /dev/null 2>&1"
    job="30 06 * * * $command"
    BTKmakeCron "$command" "$job"
    BTKcmdCheck 'sysstatReport.sh cron installation.'
  else
    BTKerror 'sysstatReport.sh failed to download.'
  fi
fi
BTKpause

BTKinfo 'Downloading emailUpgrades.sh...'
if wget https://raw.githubusercontent.com/srvr-au/bums/main/cron/emailUpgrades.sh &&
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/emailUpgrades.sig &&
  gpg --verify emailUpgrades.sig emailUpgrades.sh; then
  rm emailUpgrades.sig
  BTKsuccess 'emailUpgrades.sh downloaded and verified...'
  mv emailUpgrades.sh cron/emailUpgrades.sh
  BTKcmdCheck 'Move emailUpgrades.sh to cron directory.'
  chmod +x cron/emailUpgrades.sh
  BTKcmdCheck 'chmod emailUpgrades.sh executable.'
  command="/root/bums/cron/emailUpgrades.sh > /dev/null 2>&1"
  job="30 08 * * * $command"
  BTKmakeCron "$command" "$job"
  BTKcmdCheck 'emailUpgrades.sh cron installation.'
else
  BTKerror 'emailUpgrades.sh failed to download.'
fi
BTKpause

BTKinfo 'Downloading rebootCheck.sh...'
if wget https://raw.githubusercontent.com/srvr-au/bums/main/cron/rebootCheck.sh &&
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/rebootCheck.sig &&
  gpg --verify rebootCheck.sig rebootCheck.sh; then
  rm rebootCheck.sig
  BTKsuccess 'rebootCheck.sh downloaded and verified...'
  mv rebootCheck.sh cron/rebootCheck.sh
  BTKcmdCheck 'Move rebootCheck.sh to cron directory.'
  chmod +x cron/rebootCheck.sh
  BTKcmdCheck 'chmod rebootCheck.sh executable.'
  command="/root/bums/cron/rebootCheck.sh > /dev/null 2>&1"
  job="@reboot $command"
  BTKmakeCron "$command" "$job"
  BTKcmdCheck 'rebootCheck.sh cron installation'
else
  BTKerror 'rebootCheck.sh failed to download...'
fi
BTKpause

BTKinfo 'Downloading rblCheck.sh...'
if wget https://raw.githubusercontent.com/srvr-au/bums/main/cron/rblCheck.sh &&
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/rblCheck.sig &&
  gpg --verify rblCheck.sig rblCheck.sh; then
  rm rblCheck.sig
  BTKsuccess 'rblCheck.sh downloaded and verified...'
  mv rblCheck.sh cron/rblCheck.sh
  BTKcmdCheck 'Move rblCheck.sh to cron directory.'
  chmod +x cron/rblCheck.sh
  BTKcmdCheck 'chmod rblCheck.sh executable.'
  command="/root/bums/cron/rblCheck.sh > /dev/null 2>&1"
  job="30 07 * * * $command"
  BTKmakeCron "$command" "$job"
  BTKcmdCheck 'rblCheck.sh cron installation'
else
  BTKerror 'rblCheck.sh failed to download...'
fi
BTKpause