# Bash Ubuntu Management Scripts

Login as root to a clean install of Ubuntu 22.04 or greater
run the following commands:
```
wget https://raw.githubusercontent.com/srvr-au/bums/main/install.sh
chmod +x install.sh
./install.sh
```

## What install.sh does...
- make dir /root/bums and change to it
- download script signing public key and install on keyring
- download install1.sh and install.sig and verify
- run install1.sh

## What install1.sh does...
