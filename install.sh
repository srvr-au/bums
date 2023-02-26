#!/bin/bash

echo 'Creating /root/bums for install files.'
mkdir /root/bums
cd /root/bums

echo 'Download and install srvr public key'
if wget https://srvr-au.bitbucket.io/verifyscript.pubkey && gpg --import verifyscript.pubkey; then
  rm verifyscript.pubkey
else
  echo 'Something went wrong. Exiting 1.'
  exit
fi

echo 'Download first install file and verify gpg signature'
if wget https://cdn.jsdelivr.net/gh/srvr-au/bums/install1.sh && wget https://cdn.jsdelivr.net/gh/srvr-au/bums/gpgsigs/install1.sig && gpg --verify install1.sig install1.sh; then
  rm install1.sig
  chmod +x install1.sh
else
  echo 'Something went wrong. Exiting 2.'
  exit
fi
echo 'Running install1.sh'
./install1.sh