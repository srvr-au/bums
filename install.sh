#!/bin/bash

echo 'Creating /root/bums for install files...'
mkdir /root/bums
cd /root/bums
echo '...Done'

if command -v unminimize &>/dev/null; then
  echo 'Looks like we have a minimal install, unminimizing...'
  yes | unminimize
  echo '...Done'
fi

echo 'Download and install srvr public key...'
if wget https://srvr-au.bitbucket.io/verifyscript.pubkey &>/dev/null &&
  gpg --import verifyscript.pubkey &>/dev/null; then
  rm verifyscript.pubkey
  echo '...Done'
else
  echo 'Something went wrong. Exiting...'
  exit
fi

echo 'Download install1.sh and verify gpg signature'
if wget https://raw.githubusercontent.com/srvr-au/bums/main/install1.sh &>/dev/null && 
  wget https://raw.githubusercontent.com/srvr-au/bums/main/gpgsigs/install1.sig &>/dev/null &&
  gpg --verify install1.sig install1.sh &>/dev/null; then
  rm install1.sig
  chmod +x install1.sh
else
  echo 'Something went wrong. Exiting...'
  exit
fi
echo 'We are ready to run install1.sh...'
echo -e "When ready press any key to continue..."
read -n 1 -s

./install1.sh