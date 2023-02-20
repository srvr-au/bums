Bash Ubuntu Management Scripts
===============================
Not ready yet - in progress.

Login as root to a clean install of ubuntu 22.04 or greater

# Download and install public gpg key
wget https://srvr-au.bitbucket.io/verifyscript.pubkey
gpg --import verifyscript.pubkey
rm verifyscript.pubkey

# download first install file and verify signature
wget https://cdn.jsdelivr.net/gh/srvr-au/bums/install1.sh
wget https://cdn.jsdelivr.net/gh/srvr-au/bums/gpgsigs/install1.sig
gpg --verify install1.sig install1.sh
rm install1.sig
chmod +x install1.sh
./install1.sh
