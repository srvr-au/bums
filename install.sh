#!/bin/bash
screen -S bumsInstall /bin/bash "$0"
clear
echo 'Bash Ubuntu Management Scripts (BUMS)'
echo -e 'Server Setup Script/s\n'

echo 'Creating /root/bums for install files...'
if mkdir /root/bums &&
cd /root/bums; then
  echo -e '...Done\n'
else
  echo 'Fatal Error 1, exiting...'
  exit
fi

if command -v unminimize &>/dev/null; then
  echo 'Looks like we have a minimal install, unminimizing...'
  yes | unminimize
  echo -e '...Done\n'
fi

echo 'Download and install srvr public key...'
if wget https://srvr-au.bitbucket.io/verifyscript.pubkey &>/dev/null &&
  gpg --import verifyscript.pubkey &>/dev/null &&
  rm verifyscript.pubkey; then
  echo -e '...Done\n'
else
  echo 'Fatal Error 3, exiting...'
  exit
fi

echo 'Download install1.sh and verify gpg signature'
if wget https://raw.githubusercontent.com/srvr-au/bums/main/install1.sh &>/dev/null && 
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/install1.sig &>/dev/null &&
  gpg --verify install1.sig install1.sh &>/dev/null &&
  rm install1.sig &&
  chmod +x install1.sh; then
    echo -e 'Success... install1.sh downloaded, verified and made executable.\n'
else
  echo 'Fatal Error 4, exiting...'
  exit
fi
echo 'We are ready to run install1.sh...'
echo -e "When ready press any key to continue..."
read -n 1 -s

./install1.sh