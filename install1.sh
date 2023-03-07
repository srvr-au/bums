#!/bin/bash

vtext='1.00'
usetext='This script is requires a clean
  install of Ubuntu, at least version 22.04.
  This script sets up a simple basic server
  with the option of a basic email capacity (msmtp-mta and mailx),
  You will need to run install2.sh if you want a fully
  fledged MTA (Postfix). msmtp is best used in
  scenarios that do not need to receive mail,
  just send occasional mail. Examples
  include DNS Server, Backup or other storage
  Server, SQL Server etc.
  msmtp requires smtp settings such as an email
  username, password, hostname, and SSL port (587).'

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
if [[ $( pwd ) != '/root/bums' ]]; then
  mkdir /root/bums
  cd /root/bums
fi
[[ -f bashTK ]] && { echo 'This script can only run once.'; exit; }

echo -e "Please wait while I grab a needed file...\n\n"
if wget https://raw.githubusercontent.com/srvr-au/bashTK/main/bashTK &&
  wget https://raw.githubusercontent.com/srvr-au/bashTK/main/bashTK.sig &&
  gpg --verify bashTK.sig bashTK; then
  rm bashTK.sig
  echo -e "\n\nFile downloaded and verified, press any key to clear and continue"
  read -n 1 -s
  clear
else
  echo 'Fatal Error! exiting...'
  exit
fi

source bashTK
echo -e "${btkBlu}========================${btkRes}\n${btkBlu}Bash Ubuntu Management Scripts (BUMS)${btkRes}\n${btkBlu}========================${btkRes}\n"
echo -e "${usetext}\n\n"
BTKpause

BTKheader 'Initial Server Check'
thisOS=$( lsb_release -is )
thisVer=$( lsb_release -rs )
echo -e "This software is best run on a clean install of Ubuntu, version greater than 22.03"
[[ $thisOS == 'Ubuntu' ]] && BTKsuccess 'Good, looks like we are running Ubuntu.' || BTKfatalError "The OS is not Ubuntu"
[[ $(bc -l <<< "$thisVer > 22.03") -eq 1 ]] && BTKsuccess 'Good, looks like we are running the required version.' || BTKfatalError "The Version needs to be greater than 22.04"
BTKpause

BTKinfo 'Time to update our repository information...'
apt update
BTKcmdCheck 'Update Repository'
BTKinfo "The current Hostname is $( hostname )"
BTKaskConfirm "Enter new Hostname or enter to leave unchanged."
[[ $btkAnswer != '' ]] && hostnamectl set-hostname $btkAnswer
BTKinfo "The current Hostname is $( hostname )"
BTKinfo "The current Timezone info is\n$( timedatectl )"
BTKaskConfirm "Enter new Timezone or enter to leave unchanged."
[[ $btkAnswer != '' ]] && timedatectl set-timezone $btkAnswer
BTKinfo "The current Timezone info is\n$( timedatectl )"
BTKinfo "Adding a couple of alises...\nThe Command srvrup will upgrade the server\nThe Command srvrboot will reboot the server."
touch /root/.bash_aliases
echo 'alias srvrup="apt update; apt full-upgrade -y;"
alias srvrboot="systemctl reboot;"' >> /root/.bash_aliases
BTKcmdCheck 'Add bash aliases'

echo "Making VIM the default editor and making tabs equal 2 spaces."
touch /root/.bashrc
echo "export EDITOR='vim'
export VISUAL='vim'
" >> /root/.bashrc
BTKcmdCheck 'VIM made default editor.'

touch /root/.vimrc
echo ':set shiftwidth=2
:set tabstop=2' >> /root/.vimrc
BTKcmdCheck 'Set Tab to 2 spaces.'
BTKpause

swap=$( free -m | grep Swap: | awk '{print $2}' )
if [[ "$swap" -eq 0 ]]; then
  BTKheader 'Create SWAP (virtual RAM).'
  BTKinfo 'Looks like you have no swap. In this age of Super fast SSD, allocating some disk space to swap makes sense.'
  ram=$( free -m | grep Mem: | awk '{print $2}' )
  BTKinfo "You have $ram mb of RAM and below is your Disk Usage."
  df -h /
  BTKaskConfirm 'Enter in whole numbers the amount of GB you wish to allocate for swap. 0 for none.'
  if [[ $btkAnswerEng =~ ^[1-9]+$ ]]; then
    fallocate -l ${btkAnswerEng}GB /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    BTKbackupOrigConfig '/etc/fstab'
    echo '/swapfile          swap            swap    defaults        0 0' >> /etc/fstab
    mount -a
    BTKinfo 'Here is your new Memory Stats'
    free
  else
    BTKinfo 'You chose not to enable Swap.'
  fi
  BTKpause
else
  echo 'Looks like you already have swap enabled...'
fi

BTKheader 'Install Packages'
echo 'Looks like it is time to install a few packages...'
install=()
BTKask 'Would you like to install sysstat (System Statistics)... ?'
[[ ${btkYN} == 'y' ]] && install+=('sysstat') || echo 'No sysstat for you then...'
BTKask 'Would you like to install msmtp-mta (simple server email), rather than Postfix... ?'
if [[ ${btkYN} == 'y' ]]; then 
  install+=('msmtp-mta bsd-mailx')
  BTKask 'Would you like to install logwatch... ?'
  [[ ${btkYN} == 'y' ]] && install+=('logwatch') || echo 'No Logwatch for you then...'
else
  echo 'You will need to run install2 after reboot in order to install Postfix. Every Server needs an MTA...'
fi
echo -e "We will try to install the following software\n${install[@]}\n"
BTKpause
BTKinstall ${install[@]}
BTKpause

if BTKisInstalled 'sysstat'; then
  echo 'Just enabling sysstat'
  BTKenable 'sysstat'
  BTKgetStatus 'sysstat'
  BTKpause
fi

if BTKisInstalled 'msmtp-mta'; then
  BTKheader 's-nail configuration'
  BTKinfo "Mail on this server will be sent to an SMTP Server for delivery...${btkReturn}You will need hostname, username and password as well as port number (usually 587)."
  BTKaskConfirm 'SMTP Server Hostname'
  mtahost=$btkAnswerEng
  BTKaskConfirm 'SMTP Server Username'
  mtauser=$btkAnswerEng
  BTKaskConfirm 'SMTP Server Username Password'
  mtapass=$btkAnswerEng
  BTKask 'SMTP Server TLS Port (y for 587, n for 465)'
  if [[ $btkYN == 'y' ]]; then
    mtatype='submission'
    mtaport='587'
  else
    mtatype='smtps'
    mtaport='465'
  fi
  BTKinfo 'All email is sent to root, what email address will root send to?'
  BTKaskConfirm 'Root email address'
  mtaroot=$btkAnswerEng
  BTKaskConfirm 'From email address, y for root email or input another email address.'
  [[ $btkAnswerEng == 'y' ]] && mtafrom=$mtaroot || mtafrom=$btkAnswerEng
  
  echo "
defaults
############
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
syslog on

account srvr
###############
host ${mtahost}
port ${mtaport}
from ${mtafrom}
auth on
user ${mtauser}
password ${mtapass}

account default : srvr

aliases /etc/aliases
" >> /root/.msmtprc
  chmod 600 /root/.msmtprc
  BTKcmdCheck 'chmod /root/.msmtprc 600.'

  echo "
set sendmail="/usr/bin/msmtp"
set mta="/usr/bin/msmtp"
  " >> /root/.mailrc
  BTKcmdCheck 'configure /root/.mailrc'

  chmod 600 /root/.mailrc
  BTKcmdCheck 'chmod /root/.mailrc 600.'

  echo "
root: $mtaroot
default: root
" >> /etc/aliases
  BTKcmdCheck 'Write root email address into aliases file.'
  
  BTKpause
  
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
  echo '
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "always";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

  BTKcmdCheck 'Enable unattended upgrades to send mail and not reboot'
  
  BTKpause
  BTKheader 'Install cron jobs...'
  mkdir -p /root/bums/cron/graphs
  BTKcmdCheck 'Make cron/graphs Directory.'

  if BTKisInstalled 'sysstat'; then
  if wget https://raw.githubusercontent.com/srvr-au/bums/main/cron/sysstatReport.sh &&
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/sysstatReport.sig &&
  gpg --verify sysstatReport.sig sysstatReport.sh; then
    rm sysstatReport.sig
    BTKsuccess 'sysstatReport.sh downloaded and verified...'
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

  else
    echo 'Every Server needs some way to send mail - so you will need to install Postfix.'
    echo 'Downloading install2.sh, run it after reboot...'
    if wget https://raw.githubusercontent.com/srvr-au/bums/main/install2.sh; then
      BTKsuccess 'install2.sh download successful.'
      chmod +x install2.sh
      BTKcmdCheck 'chmod install2.sh executable'
    else
      echo 'install2.sh download failed.'
    fi
  fi
BTKpause

BTKheader 'Uncomplicated Firewall open ssh and enable.'
if BTKisInstalled 'ufw'; then
  BTKask 'You have Uncomplicated Firewall (UFW) installed, do you want to allow OpenSSH and Enable.'
  if [[ $btkYN == 'y' ]]; then
    if ufw allow OpenSSH; then
      BTKsuccess 'Firewall allow OpenSSH.'
      # echo "y" | ufw enable
      if ufw --force enable; then
        BTKsuccess 'Firewall enabled.'
        ufw status
      else
        BTKerror 'Firewall failed to enable.'
      fi
    else
      BTKerror 'Firewall failed to allow OpenSSH and NOT enabled.'
    fi
  else
    echo 'OK, no Uncomplicated Firewall for you then...'
  fi
else
  BTKwarn 'Uncomplicated firewall not installed.'
fi
BTKpause

BTKheader 'Finish: Upgrade and Reboot'
echo 'Now we will upgrade all Server Software... then reboot'
BTKpause
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
systemctl reboot
