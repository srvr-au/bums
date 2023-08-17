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
  gpg --verify bashTK.sig bashTK &>/dev/null &&
  rm bashTK.sig &&
  source bashTK; then
    BTKsuccess 'bashTK downloaded, verified and loaded.'
else
  echo 'Fatal Error! Exiting...'
  exit
fi

BUMScronDownload(){
BTKinfo "Downloading ${1}.sh..."
bumsCommand=''
if wget https://raw.githubusercontent.com/srvr-au/bums/main/cron/${1}.sh &>/dev/null &&
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/${1}.sig &>/dev/null &&
  gpg --verify ${1}.sig ${1}.sh &>/dev/null &&
  rm ${1}.sig; then
    BTKsuccess "${1}.sh downloaded and verified..."
    mv ${1}.sh /root/bums/cron/${1}.sh
    BTKcmdCheck "Move ${1}.sh to cron directory."
    chmod +x /root/bums/cron/${1}.sh
    BTKcmdCheck "chmod ${1}.sh executable."
    bumsCommand="/root/bums/cron/${1}.sh > /dev/null 2>&1"
    sleep 1
else
  BTKerror "${1}.sh failed to download..."
fi
}

echo -e "${btkPurBg} ${btkReset}\n${btkPurFg}Bash Ubuntu Management Scripts (BUMS)${btkReset}\n${btkPurBg} ${btkReset}\n"
echo -e "${usetext}\n\n"

BTKpause
BTKheader 'Initial Server Check'
thisOS=$( lsb_release -is )
thisVer=$( lsb_release -rs )
BTKinfo 'This software is best run on a clean install of Ubuntu, version greater than 22.03'
[[ $thisOS == 'Ubuntu' ]] && BTKsuccess 'Good, looks like we are running Ubuntu.' || BTKfatalError "The OS is not Ubuntu"
[[ $(bc -l <<< "$thisVer > 22.03") -eq 1 ]] && BTKsuccess 'Good, looks like we are running the required version.' || BTKfatalError "The Version needs to be greater than 22.04"

sleep 2
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
        BTKsuccess 'You now have an authorized_keys file, test you can SSH in using keys.'
        BTKpause
        break
      else
        BTKwarn 'Installing your key failed, sorry!'
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
      BTKinfo 'You should copy your Private Key and Password and save it locally and use it to SSH in.'
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

sleep 2
BTKheader 'Operating System Tweaks'
BTKinfo 'Your hostname in most instances should be a fully qualified FQDN ie somename.srvr.au'
BTKinfo 'Your DNS should also resolve this hostname to the local ip address.'
BTKinfo "The current Hostname is $( hostname )"
BTKaskConfirm "Enter new Hostname or enter to leave unchanged."
[[ $btkAnswer != '' ]] && hostnamectl set-hostname $btkAnswer
BTKinfo "The current Hostname is $( hostname )"

BTKinfo "The current Timezone info is\n$( timedatectl )"
BTKaskConfirm "Enter new Timezone (in form Australia/Sydney) or enter to leave unchanged."
[[ $btkAnswer != '' ]] && timedatectl set-timezone $btkAnswer
BTKinfo "The current Timezone info is\n$( timedatectl )"

sleep 2
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
echo -e "\n\e[0;30;102m\e[K CPU Information\e[0m"
echo -e "$( iostat -c )"
echo -e "\n\e[0;30;102m\e[K Disk Information\e[0m"
echo -e "$( df -h -x tmpfs )"
echo -e "\n\e[0;30;102m\e[K Memory Information\e[0m"
echo -e "$( free )"
echo -e "\n\e[0;30;102m\e[K $( grep " can be applied immediately." /var/lib/update-notifier/updates-available )\e[0m"
[[ -f /var/run/reboot-required ]] && echo -e "\e[0;30;101m\e[K $( cat /var/run/reboot-required )\e[0m"
echo -e "\n"
EOF
BTKcmdCheck 'VIM made default editor.'

touch /root/.vimrc
echo ':set shiftwidth=2
:set tabstop=2' >> /root/.vimrc
BTKcmdCheck 'Set Tab to 2 spaces.'

sleep 2
BTKheader 'Check SWAP (virtual RAM).'
swap=$( free -m | grep Swap: | awk '{print $2}' )
if [[ "$swap" -eq 0 ]]; then
  BTKinfo 'Looks like you have no swap. In this age of Super fast SSD, allocating some disk space to swap makes sense.'
  BTKinfo 'I like to have 4gb swap, minimum.'
  ram=$( free -m | grep Mem: | awk '{print $2}' )
  BTKinfo "You have $ram mb of RAM and below is your Disk Usage."
  df -h /
  BTKaskConfirm 'Enter in whole numbers the amount of GB you wish to allocate for swap. 0 for none.'
  if [[ $btkAnswerEng =~ ^[1-9]+$ ]]; then
    btkRunCommands=("fallocate -l ${btkAnswerEng}GB /swapfile" 'chmod 600 /swapfile' 'mkswap /swapfile' 'swapon /swapfile' "BTKbackupOrigConfig /etc/fstab")
    BTKrun
    echo '/swapfile          swap            swap    defaults        0 0' >> /etc/fstab
    BTKcmdCheck 'Add swapfile to fstab.'
    mount -a
    BTKcmdCheck 'Mount swapfile.'
    BTKinfo 'Here is your new Memory Stats'
    free
  else
    BTKinfo 'You chose not to enable Swap.'
  fi
else
  BYKinfo 'Looks like you already have swap enabled...'
fi

BTKpause
BTKheader 'Uncomplicated Firewall - open ssh and enable.'
if BTKisInstalled 'ufw'; then
  BTKask 'You have Uncomplicated Firewall (UFW) installed, do you want to open port 22 and enable UFW?'
  if [[ $btkYN == 'y' ]]; then
    if ufw limit 22/tcp &>/dev/null; then
      BTKsuccess 'Firewall limit port 22/tcp.'
      # echo "y" | ufw enable
      if ufw --force enable; then
        BTKsuccess 'Firewall enabled.'
        BTKinfo 'Below is your UFW status.'
        ufw status
      else
        BTKwarn 'Firewall failed to enable, do it manually.'
      fi
    else
      BTKwarn 'Firewall failed to open port 22, therefore UFW NOT enabled, do it manually.'
    fi
  else
    BTKinfo 'OK, no Uncomplicated Firewall for you then...'
  fi
else
  BTKwarn 'Uncomplicated Firewall not installed. You should use a Firewall.'
fi

BTKpause
BTKheader 'Install Packages'
install=()
BTKinfo 'msmtp-mta sends mail via Port 587, it is fine for sending small amounts of email and/or where your Instance has port 25 blocked. If Port 25 is not blocked by your provider or you wish to receive mail, install Postfix via install2.sh instead.'
BTKask 'Would you like to install msmtp-mta (simple server email), rather than Postfix... ?'
if [[ ${btkYN} == 'y' ]]; then 
  install+=('msmtp-mta s-nail')
  BTKask 'Would you like to install logwatch... ?'
  [[ ${btkYN} == 'y' ]] && install+=('logwatch') || BTKinfo 'No Logwatch for you then...'
  BTKask 'Would you like to install sysstat (System Statistics)... ?'
  [[ ${btkYN} == 'y' ]] && install+=('sysstat') || BTKinfo 'No sysstat for you then...'
  
  echo -e "${btkGreFg}We will try to install the following software:${btkReturn}${install[@]}${btkReset}\n"
  BTKpause
  BTKinstall ${install[@]}
  
  BTKpause
  if BTKisInstalled 'msmtp-mta'; then

    BTKheader 'msmtp-mta and s-nail configuration'
    BTKinfo "Mail on this server will be sent to an SMTP Server for delivery...${btkReturn}You will need hostname, username and password as well as port number (usually 587)."
    BTKaskConfirm 'SMTP Server Hostname'
    mtahost=$btkAnswerEng
    BTKaskConfirm 'SMTP Server Username'
    mtauser=$btkAnswerEng
    BTKaskConfirm 'SMTP Server Username Password'
    mtapass=$btkAnswerEng
    while true; do
      btkMenuOptions=('587' '465')
      BTKmenu 'n' 'SMTP Server TLS Port (usually 587)'
      if [[ $btkMenuAnswer == 'a' ]]; then
        mtatype='submission'
        mtaport='587'
        break
      elif [[ $btkMenuAnswer == 'b' ]]; then
        mtatype='smtps'
        mtaport='465'
        break
      elif [[ $btkMenuAnswer == 'x' ]]; then
        BTKexit
      fi
    done
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
    BTKcmdCheck 'msmtp-mta configuration'
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
    newaliases
    
    BTKpause
    BTKheader 'Lets configure some scripts'
    if BTKisInstalled 'sysstat'; then
      BTKinfo 'Just enabling sysstat'
      BTKenable 'sysstat'
      BTKgetStatus 'sysstat'
    fi
    sleep 1
    if BTKisInstalled 'logwatch'; then
      BTKinfo 'Configure Logwatch'
      mkdir /var/cache/logwatch
      echo 'Output = mail
Format = text
MailTo = root
Range = yesterday
Detail = low
Service = All
Service = "-sshd"
' > /etc/logwatch/conf/logwatch.conf
      BTKcmdCheck 'Logwatch configuration'
    fi

    sleep 1
    BTKinfo 'Configure Unattended Upgrades.'
    echo 'Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "always";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
' >> /etc/apt/apt.conf.d/50unattended-upgrades
    BTKcmdCheck 'Enable unattended upgrades'

    sleep 1
    BTKheader 'Install cron files and jobs...'
    mkdir /root/bums/cron
    BTKcmdCheck 'Make cron Directory.'

    if BTKisInstalled 'sysstat'; then
      mkdir /root/bums/cron/graphs
      bumsScript='sysstatReport'
      BTKinfo "Download and install cron - ${bumsScript}.sh"
      BUMScronDownload "${bumsScript}"
      if [[ -n ${bumsCommand} ]]; then
        bumsJob="30 06 * * * $bumsCommand"
        BTKmakeCron "$bumsCommand" "$bumsJob"
        BTKcmdCheck "${bumsScript}.sh cron installation"
      else
        BTKwarn "${bumsScript}.sh cron job failed to be added."
      fi
    fi

    sleep 1
    bumsScript='emailUpgrades'
    BTKinfo "Download and install cron - ${bumsScript}.sh"
    BUMScronDownload "${bumsScript}"
    if [[ -n ${bumsCommand} ]]; then
      bumsJob="30 08 * * * $bumsCommand"
      BTKmakeCron "$bumsCommand" "$bumsJob"
      BTKcmdCheck "${bumsScript}.sh cron installation"
    else
      BTKwarn "${bumsScript}.sh cron job failed to be added."
    fi

    sleep 1
    bumsScript='rebootCheck'
    BTKinfo "Download and install cron - ${bumsScript}.sh"
    BUMScronDownload "${bumsScript}"
    if [[ -n ${bumsCommand} ]]; then
      bumsJob="@reboot $bumsCommand"
      BTKmakeCron "$bumsCommand" "$bumsJob"
      BTKcmdCheck "${bumsScript}.sh cron installation"
    else
      BTKwarn "${bumsScript}.sh cron job failed to be added."
    fi

    sleep 1
    bumsScript='rblCheck'
    BTKinfo "Download and install cron - ${bumsScript}.sh"
    BUMScronDownload "${bumsScript}"
    if [[ -n ${bumsCommand} ]]; then
      bumsJob="30 07 * * * $bumsCommand"
      BTKmakeCron "$bumsCommand" "$bumsJob"
      BTKcmdCheck "${bumsScript}.sh cron installation"
    else
      BTKwarn "${bumsScript}.sh cron job failed to be added."
    fi
  
  else
    BTKfatalError 'Looks like msmtp-mta failed to install.'
  fi
fi

BTKheader 'Install2.sh download.'
BTKinfo 'Install2.sh will install Nginx web server and/or Postfix MTA.'
BTKask 'Would you like to download and execute install2.sh...?'
if [[ ${btkYN} == 'y' ]]; then
  BTKinfo 'Downloading install2.sh...'
  if wget https://raw.githubusercontent.com/srvr-au/bums/main/install2.sh &>/dev/null &&
    wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/install2.sig &>/dev/null &&
    gpg --verify install2.sig install2.sh &>/dev/null; then
    BTKsuccess 'install2.sh downloaded and verified.'
    rm install2.sig
    chmod +x install2.sh
    BTKcmdCheck 'chmod install2.sh executable'
    ./install2.sh
  else
    BTKwarn 'install2.sh download failed.'
  fi
else
  BTKpause
  BTKheader 'Finish: Upgrade and Reboot'
  BTKinfo 'Time to update our repository information.'
  BTKinfo 'Please wait...'
  apt update &>/dev/null
  BTKcmdCheck 'Update Repository'
  BTKinfo 'Now we will upgrade all Server Software... then reboot'
  sleep 1
  DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
  BTKsuccess 'Please wait for the system to reboot...'
  sleep 1
  systemctl reboot
fi