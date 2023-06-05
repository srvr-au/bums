#!/bin/bash

vtext='1.00'
usetext='This script is requires a clean
  install of Ubuntu, at least version 22.04.
  This script sets up a simple basic server
  instance with the option of basic email sending
  capacity (msmtp-mta and s-nail).
  You will need to run install2.sh after install1.sh
  if you want a fully fledged MTA (Postfix).
  msmtp is best used in
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
[[ -f install.sh ]] && rm install.sh 

echo 'Please wait while I grab bashTK (Bash ToolKit) file...'
if wget https://raw.githubusercontent.com/srvr-au/bashTK/main/bashTK &>/dev/null &&
  wget https://raw.githubusercontent.com/srvr-au/bashTK/main/bashTK.sig &>/dev/null &&
  gpg --verify bashTK.sig bashTK &>/dev/null; then
  rm bashTK.sig
  source bashTK
  BTKsuccess 'bashTK downloaded, verified and loaded, press any key to clear and continue...'
  read -n 1 -s
  clear
else
  echo 'Fatal Error! Exiting...'
  exit
fi

echo -e "${btkBlu}========================${btkRes}\n${btkBlu}Bash Ubuntu Management Scripts (BUMS)${btkRes}\n${btkBlu}========================${btkRes}\n"
echo -e "${usetext}\n\n"

BTKpause
BTKheader 'Initial Server Check'
thisOS=$( lsb_release -is )
thisVer=$( lsb_release -rs )
BTKinfo 'This software is best run on a clean install of Ubuntu, version greater than 22.03'
[[ $thisOS == 'Ubuntu' ]] && BTKsuccess 'Good, looks like we are running Ubuntu.' || BTKfatalError "The OS is not Ubuntu"
[[ $(bc -l <<< "$thisVer > 22.03") -eq 1 ]] && BTKsuccess 'Good, looks like we are running the required version.' || BTKfatalError "The Version needs to be greater than 22.04"

BTKpause
BTKheader 'Check SSH configuration, harden SSH'
if [[ -s /root/.ssh/authorized_keys ]]; then
  BTKsuccess 'Looks like you may have an SSH public key installed'
else
  touch /root/.ssh/authorized_keys
  BTKwarn 'You have an empty authorized_keys file, therefore you are not using SSH keys.'
  while true; do
    btkMenuOptions=('Paste SSH public key into terminal' 'Create SSH Keypair on server' 'I will do it manually later.')
    BTKmenu
    if [[ $btkMenuAnswer == 'a' ]]; then
      read -p 'Paste your PUBLIC SSH Key here: ' pubKey
      echo "${pubKey}" >> /root/.ssh/authorized_keys
      if [[ -s /root/.ssh/authorized_keys ]]; then
        echo 'You now have an authorized_keys file, test you can SSH in using keys.'
        BTKpause
        break
      else
        echo 'Installing your key failed, sorry!'
        BTKpause
        break
      fi
    elif [[ $btkMenuAnswer == 'b' ]]; then
      pass=$( BTKrandLetters )
      ssh-keygen -t ed25519 -N ${pass} -C root@${btkHost} -f /root/.ssh/id_ed25519 &>/dev/null
      cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys
      [[ -s /root/.ssh/authorized_keys ]] && BTKsuccess 'Public Key saved in authorized_keys file.' || BTKwarn 'Public Key not saved in authorized key file, do it manually.'
      BTKinfo 'Your Private Key is located at /root/.ssh/id_ed25519'
      BTKinfo 'Your Public Key is located at /root/.ssh/id_ed25519.pub'
      echo "Your Private Key Password is : $pass"
      echo "Your Private Key is : "
      echo "$( </root/.ssh/id_ed25519 )"
      echo 'You should copy your Private Key and Password and save it locally and use it to SSH in.'
      BTKpause
      break
    else
      echo 'You chose to quit or do it manually later'
      break;
    fi
  done
fi
pwauth=$( awk '/^PasswordAuthentication / {print $2}' /etc/ssh/sshd_config )
[[ $pwauth == 'yes' ]] && BTKwarn 'Your SSH config allows Password Authentication, set PasswordAuthentication to no and use SSH keys instead.' || BTKsuccess 'No Password Authentication, very good!'

[[ -f /etc/ssh/sshd_config.d/99-srvr.conf ]] && rm /etc/ssh/sshd_config.d/99-srvr.conf
echo '
MaxStartups 2:30:10
LoginGraceTime 30
' > /etc/ssh/sshd_config.d/99-srvr.conf
BTKcmdCheck 'SSH hardened.'

BTKpause
BTKheader 'Operating System Tweaks'
BTKinfo 'Time to update our repository information...'
apt update &>/dev/null
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

BTKinfo 'Making VIM the default editor, tabs equal 2 spaces and ssh login info.'
touch /root/.bashrc
tee -a /root/.bashrc <<'EOF' >/dev/null
export EDITOR='vim'
export VISUAL='vim'
echo -e "\n=============================="
echo "$( hostname ) - $( hostname -i )"
echo ''
cpus=$( nproc )
read -r a b c d < /proc/loadavg
onef=$( bc  <<< "scale=2; $a/$cpus" )
twof=$( bc  <<< "scale=2; $b/$cpus" )
threef=$( bc  <<< "scale=2; $c/$cpus" )
echo "CPU Usage (1 5 15): $onef% $twof% $threef%"
echo -e "\n            Total Used Free"
echo "Disk Space: $( df -h | grep -w / | awk '{ print $2" "$3" "$4 }' )"
echo "Memory:     $( free -h --si | grep -w Mem: | awk '{ print $2" "$3" "$4 }' )"
echo "Swap:       $( free -h --si | grep -w Swap: | awk '{ print $2" "$3" "$4 }' )"
echo ''
echo $( grep " can be applied immediately." /var/lib/update-notifier/updates-available )
[[ -f /var/run/reboot-required ]] && cat /var/run/reboot-required
echo -e "==============================\n"
EOF
BTKcmdCheck 'VIM made default editor.'

touch /root/.vimrc
echo ':set shiftwidth=2
:set tabstop=2' >> /root/.vimrc
BTKcmdCheck 'Set Tab to 2 spaces.'

BTKpause
BTKheader 'Check SWAP (virtual RAM).'
swap=$( free -m | grep Swap: | awk '{print $2}' )
if [[ "$swap" -eq 0 ]]; then
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
else
  echo 'Looks like you already have swap enabled...'
fi

BTKpause
BTKheader 'Uncomplicated Firewall - open ssh and enable.'
if BTKisInstalled 'ufw'; then
  BTKask 'You have Uncomplicated Firewall (UFW) installed, do you want to allow OpenSSH and Enable.'
  if [[ $btkYN == 'y' ]]; then
    if ufw limit 22/tcp &>/dev/null; then
      BTKsuccess 'Firewall limit port 22/tcp.'
      # echo "y" | ufw enable
      if ufw --force enable; then
        BTKsuccess 'Firewall enabled.'
        BTKinfo 'Below is your UFW status.'
        ufw status
      else
        BTKerror 'Firewall failed to enable.'
      fi
    else
      BTKerror 'Firewall failed to allow OpenSSH and NOT enabled.'
    fi
  else
    BTKwarn 'OK, no Uncomplicated Firewall for you then...'
  fi
else
  BTKwarn 'Uncomplicated firewall not installed.'
fi

BTKpause
BTKheader 'Install Packages'
install=()
BTKinfo 'msmtp-mta sends mail via Port 587, it is fine for sending small amounts of email and/or where your Instance has port 25 blocked. If Port 25 is not blocked by your provider or you wish to receive mail, install Postfix via install2.sh instead.'
BTKask 'Would you like to install msmtp-mta (simple server email), rather than Postfix... ?'
if [[ ${btkYN} == 'y' ]]; then 
  install+=('msmtp-mta s-nail')
  BTKask 'Would you like to install logwatch... ?'
  [[ ${btkYN} == 'y' ]] && install+=('logwatch') || BTKwarn 'No Logwatch for you then...'
  BTKask 'Would you like to install sysstat (System Statistics)... ?'
  [[ ${btkYN} == 'y' ]] && install+=('sysstat') || BTKwarn 'No sysstat for you then...'
  echo -e "We will try to install the following software\n${install[@]}\n"
  BTKpause
  BTKinstall ${install[@]}
  
  BTKpause
  
  if BTKisInstalled 'msmtp-mta'; then
    if BTKisInstalled 'sysstat'; then
      BTKinfo 'Just enabling sysstat'
      BTKenable 'sysstat'
      BTKgetStatus 'sysstat'
      BTKpause
    fi

    BTKheader 'msmtp and s-nail configuration'
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
  
    echo "defaults
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

    echo '#set sendmail="/usr/bin/msmtp"
set mta="/usr/bin/msmtp"
' >> /root/.mailrc
    BTKcmdCheck 'configure /root/.mailrc'

    chmod 600 /root/.mailrc
    BTKcmdCheck 'chmod /root/.mailrc 600.'
  
    ln -s /usr/bin/s-nail /usr/bin/mail
    BTKcmdCheck 'link s-nail to mail command.'

    echo "root: $mtaroot
default: root
" >> /etc/aliases
    BTKcmdCheck 'Write root email address into aliases file.'
    BTKpause
    
    BTKinfo 'Please wait while I grab a needed file...'
    if wget https://raw.githubusercontent.com/srvr-au/bashTK/main/installHelper.sh &>/dev/null &&
      wget https://raw.githubusercontent.com/srvr-au/bashTK/main/gpgsigs/installHelper.sig &>/dev/null &&
      gpg --verify installHelper.sig installHelper.sh &>/dev/null; then
      BTKsuccess 'File downloaded and verified...'
      rm installHelper.sig
      chmod +x installHelper.sh
      BTKcmdCheck 'chmod installHelper.sh executable'
    else
      BTKfatalError 'A needed file failed to download or verify'
    fi
    BTKpause
  
    ./installHelper.sh
  else
    BTKfatalError 'Looks like msmtp-mta failed to install.'
  fi
fi

BTKheader 'Install2.sh download.'
BTKinfo 'Install2.sh will install Nginx web server and/or Postfix MTA.'
BTKask 'Would you like to download install2.sh...?'
if [[ ${btkYN} == 'y' ]]; then
  BTKinfo 'Downloading install2.sh, run it after reboot...'
  if wget https://raw.githubusercontent.com/srvr-au/bums/main/install2.sh &>/dev/null &&
    wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/install2.sig &>/dev/null &&
    gpg --verify install2.sig install2.sh &>/dev/null; then
    BTKsuccess 'install2.sh downloaded and verified.'
    chmod +x install2.sh
    BTKcmdCheck 'chmod install2.sh executable'
  else
    BTKerror 'install2.sh download failed.'
  fi
fi

BTKpause
BTKheader 'Finish: Upgrade and Reboot'
BTKinfo 'Now we will upgrade all Server Software... then reboot'
BTKpause
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
systemctl reboot
