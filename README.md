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
- download install1.sh and install1.sig and verify
- run install1.sh

## What install1.sh does...
- download bashTK (my bash toolkit) and bashTK.sig and verify
- checks you are running ubuntu and at least 22.04
- runs apt update
- gives opportunity to change hostanme and timezone
- adds aliases to update (srvrup) and reboot (srvrboot)
- makes vim default editor with tabs at 2 spaces
- asks how much swap memory you want created
- if UFW (firewall) installed you can allow openssh and enable the firewall
- asks if you want to download and install msmtp-mta (a very lightweight mta)
msmtp-mta is great for a server that wont be receiving emails, just generating them.
Uses include : DNS server, Storage Server. Backup Storage. Database Server. etc
- if you choose no it will download install2.sh to install POSTFIX (and NGINX)
- if you choose yes it will ask if you want to install sysstat, logweatch, rblCheck, systatReport, rebootCheck and configure unattended-upgrades to email you
