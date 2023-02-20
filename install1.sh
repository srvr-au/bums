#!/bin/bash

vtext='1.00'
usetext='This script is requires a clean
  install of Ubuntu, at least version 22.04.
  This script sets up a simple basic server
  with the option of a basic email capacity (s-nail),
  You will need to run install2.sh if you want a fully
  fledged MTA (Postfix). s-nail is best used in
  scenarios that do not need to receive mail,
  just send occasional mail. Examples
  include DNS Server, Backup or other storage
  Server, SQL Server etc.
  s-nail requires smtp settings such as an email
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

get-bashTK(){
echo 'Please wait while I download and install the public PGP key'
if wget https://srvr-au.bitbucket.io/verifyscript.pubkey &&
  gpg --import verifyscript.pubkey; then
  echo 'PGP public key sucessfully downloaded and added to keyring'
  rm verifyscript.pubkey
else
  echo 'Fatal Error! exiting...'
  exit 1
fi
echo -e "Please wait while I grab a needed file...\n\n"
if wget https://cdn.jsdelivr.net/gh/srvr-au/bashTK@main/bashTK &&
  wget https://cdn.jsdelivr.net/gh/srvr-au/bashTK@main/bashTK.sig &&
  gpg --verify bashTK.sig bashTK; then
  rm bashTK.sig
  echo 'File downloaded and verified, press any key to clear and continue'
  read -n 1 -s
  clear
else
  echo 'Fatal Error! exiting...'
  exit 1
fi
}

run-initial(){
BTKheader 'Initial Server Check'
thisOS=$( lsb_release -is )
thisVer=$( lsb_release -rs )
echo -e "This software is best run on a clean install of Ubuntu, version greater than 22.03"
[[ $thisOS == 'Ubuntu' ]] && echo -e "${btkGre}Good, looks like we are running Ubuntu.${btkRes}" || BTKfatalError "The OS is not Ubuntu"
[[ $(bc -l <<< "$thisVer > 22.03") -eq 1 ]] && echo -e "${btkGre}Good, looks like we are running the required version.${btkRes}" || BTKfatalError "The Version needs to be greater than 22.04"
BTKcontinue
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
}

make-swap(){
BTKheader 'Create SWAP (virtual RAM).'
BTKinfo 'Looks like you have no swap. In this age of Super fast SSD, allocating some disk space to swap makes sense.'
ram=$( free -m | grep Mem: | awk '{print $2}' )
BTKinfo "You have $ram mb of RAM and below is your Disk Usage."
df -h /
BTKaskConfirm 'Enter in whole numbers the amount of GB you wish to allocate for swap. 0 for none.'
if [[ $btkAnswerEng =~ ^[1-9]+$ ]]; then
  fallocate -l ${btkAnswerEng} /swapfile
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
}

clear
if [[ $( pwd ) != '/root/bums' ]]; then
mkdir /root/bums
cd /root/bums
fi
[[ -f bashTK ]] && echo 'This script can only run once.'; exit;

get-bashTK

source bashTK
echo -e "${btkBlu}========================${btkRes}\n${btkBlu}Bash Ubuntu Management Scripts (BUMS)${btkRes}\n${btkBlu}========================${btkRes}\n"
echo -e ${usetext}

run-initial
swap=$( free -m | grep Swap: | awk '{print $2}' )
[[ "$swap" -eq 0 ]] && make-swap || echo 'Looks like you have swap enabled...'

BTKheader 'Install Packages'
echo 'Looks like it is time to install a few packages...'
install='apticron needrestart'
BTKask 'Would you like to install Uncomplicated Firewall (UFW)... ?'
[[ ${btkYN} == 'y' ]] && install+=" ufw" || echo 'No Firewall for you then...'
BTKask 'Would you like to install sysstat (System Statistics)... ?'
[[ ${btkYN} == 'y' ]] && install+=" sysstat" || echo 'No sysstat for you then...'
BTKask 'Would you like to install s-nail (simple server email), rather than Postfix... ?'
[[ ${btkYN} == 'y' ]] && install+=" s-nail" || echo 'You will need to run install2.sh to install Postfix...'
echo -e "We will install the following software\n$install\n"
BTKpause
BTKinstall $install
BTKpause
if [[ "$install" == *" sysstat"* ]]; then
  echo 'Just enabling sysstat'
  BTKenable 'sysstat'
  BTKgetStatus 'sysstat'
  BTKpause
fi

if [[ "$install" == *" ufw"* ]]; then
  echo 'Just configuring and enabling Firewall'
  ufw allow ssh
  if [[ $? -eq 0 ]]; then
    BTKsuccess "SSH Port opened"
    BTKenable 'ufw'
    BTKgetStatus 'ufw'
  else
    BTKerror "SSH Port Failed to be opened. Firewall NOT enabled."
    BTKgetStatus 'ufw'
  fi
  BTKpause
fi

if [[ "$install" == *" s-nail"* ]]; then
  echo 'Mail on this server will be sent to an SMTP Server for delivery...'
  BTKaskConfirm 'SMTP Server Hostname'
  mtahost=$btkAnswerEng
  BTKaskConfirm 'SMTP Server Username'
  mtauser=$btkAnswerEng
  BTKaskConfirm 'SMTP Server Username Password'
  mtapass=$btkAnswerEng
  BTKask 'SMTP Server TLS Port (y for 587, n for 465)'
  if [[] $btkYN == 'y' ]]; then
    mtatype='submission'
    mtaport='587'
  else
    mtatype='smtps'
    mtaport='465'
  fi
  BTKaskConfirm 'All email is sent to root, root email address'
  mtaroot=$btkAnswerEng
  BTKaskConfirm 'From email address'
  mtafrom=$btkAnswerEng

  urlencodeduser=( python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" $mtauser )
  urlencodedpass=( python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" $mtapass )

  echo "
#--------------------------------------------#
# Configure s-nail version v14.9.23            #
#--------------------------------------------#

# Testing syntax:
# echo "Testing, Testing, Testing" | mail -s "My test..." recipEmailAddr
# -v for verbose -vv for very verbose

# Use v15.0 compatibility mode
set v15-compat
set mta-aliases=/etc/aliases

# Essential setting: select allowed character sets
set sendcharsets=utf-8,iso-8859-1
# and reply in the same charset used by sender:
set reply-in-same-charset

# Default directory where we act in (relative to HOME)
set folder=mail

# Request strict TLS transport layer security checks
set tls-verify=strict
set tls-ca-file=/etc/ssl/certs/ca-certificates.crt
set tls-ca-no-defaults
set smtp-use-starttls
set smtp-auth=login

#set verbose
set sendwait
set from="${$mtafrom}"
set mta=${mtatype}://${urlencodeduser}:${urlencodedpass}@${$mtahost}:${mtaport}

#--------------------------------------------#
" >> /root/.mailrc
  BTKcmdCheck 'configure /root/.mailrc'

  chmod 600 /root/.mailrc
  BTKcmdCheck 'chmod /root/.mailrc 600.'
  ln -s /usr/bin/s-nail /usr/bin/mail
  BTKcmdCheck 'link s-nail to mail command.'

  echo "
root: $mtaroot
default: root
" >> /etc/aliases
  BTKcmdCheck 'Write root email address into aliases file.'

  mkdir -p /root/bums/cron/graphs
  BTKcmdCheck 'Make cron/graphs Directory.'

  if [[ wget https://cdn.jsdelivr.net/gh/srvr-au/bums@main/cron/sysstatReport.sh ]]; then
    BTKsuccess 'sysstatReport.sh downloaded...'
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

  if [[ wget https://cdn.jsdelivr.net/gh/srvr-au/bums@main/cron/rebootCheck.sh ]]; then
    BTKsuccess 'rebootCheck.sh downloaded...'
    mv rebootCheck.sh cron/rebootCheck.sh
    BTKcmdCheck 'Move rebootCheck.sh to cron directory.'
    chmod +x cron/rebootCheck.sh
    BTKcmdCheck 'chmod rebootCheck.sh executable.'
    command="/root/bums/cron/rebootcheck.sh > /dev/null 2>&1"
    job="@reboot $command"
    BTKmakeCron "$command" "$job"
    BTKcmdCheck 'rebootCheck.sh cron installation'
  else
    BTKerror 'rebootCheck.sh failed to download...'
  fi

  if [[ wget https://cdn.jsdelivr.net/gh/srvr-au/bums@main/cron/rblCheck.sh ]]; then
    BTKsuccess 'rblCheck.sh downloaded...'
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
    if [[ wget https://cdn.jsdelivr.net/gh/srvr-au/bums@main/install2.sh ]]; then
      BTKsuccess 'install2.sh download successful.'
      chmod +x install2.sh
      BTKcmdCheck 'chmod install2.sh executable'
    else
      echo 'install2.sh download failed.'
    fi
  BTKpause
  fi

BTKheader 'Finish: Upgrade and Reboot'
echo 'Now we will upgrade all Server Software... then reboot'
BTKpause
apt full-upgrade -y
systemctl reboot
