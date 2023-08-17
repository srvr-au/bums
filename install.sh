#!/bin/bash

echo 'Bash Ubuntu Management Scripts (BUMS)'
echo 'Server Setup Script/s'

echo 'Creating /root/bums for install files...'
if mkdir /root/bums &&
cd /root/bums; then
  echo '...Done'
else
  echo 'Fatal Error... exiting'
  exit
fi

if command -v unminimize &>/dev/null; then
  echo 'Looks like we have a minimal install, unminimizing...'
  yes | unminimize
  echo '...Done'
else
  echo 'Fatal Error... exiting'
  exit
fi

echo 'Download and install srvr public key...'
if wget https://srvr-au.bitbucket.io/verifyscript.pubkey &>/dev/null &&
  gpg --import verifyscript.pubkey &>/dev/null &&
  rm verifyscript.pubkey; then
  echo '...Done'
else
  echo 'Fatal Error... exiting'
  exit
fi

echo 'Download install1.sh and verify gpg signature'
if wget https://raw.githubusercontent.com/srvr-au/bums/main/install1.sh &>/dev/null && 
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/install1.sig &>/dev/null &&
  gpg --verify install1.sig install1.sh &>/dev/null &&
  rm install1.sig &&
  chmod +x install1.sh; then
    echo 'Success... install1.sh downloaded, verified and made executable.'
else
  echo 'Fatal Error... exiting'
  exit
fi
echo 'We are ready to run install1.sh...'
echo -e "When ready press any key to continue..."
read -n 1 -s

./install1.sh