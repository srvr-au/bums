# Bash Ubuntu Management Scripts

BUMS is a hosting management script, using Bash on Ubuntu.
I have run hosting servers for well over 25 years.
I have used cPanel, Webmin and others. They all have the same problems.
1. When web account is hacked, email is hacked too.
2. Customers are given way too many freedoms and end up doing stupid things.
3. Password logins... enough said.

BUMS separates email and web, does not allow customers access and uses SSH keys to login.
Hosting providers need to stop letting customers dictate how to run servers.
One thing I learnt was that the CUSTOMER IS ALWAYS WRONG.

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
- gives opportunity to change hostname and timezone
- adds aliases to update (srvrup) and reboot (srvrboot)
- makes vim default editor with tabs at 2 spaces
- asks how much swap memory you want created
- if UFW (firewall) installed you can allow openssh and enable the firewall
- asks if you want to download and install msmtp-mta (a very lightweight mta)
msmtp-mta is great for a server that wont be receiving emails, just generating them.
Uses include : DNS server, Storage Server. Backup Storage. Database Server. etc
- if you choose no it will download install2.sh to install POSTFIX (and NGINX)
- if you choose yes it will ask if you want to install sysstat, logwatch, rblCheck, sysstatReport, rebootCheck and configure unattended-upgrades to install security updates and email you
- it will verify my scripts and configure everything else.
- Update system and reboot

You now have a server ready for you to install DNS, Database, rsync etc

## What install2.sh does
- Check you have run install1.sh
- make sure msmtp-mta is NOT installed
- Asks if you want to install POSTFIX Dovecot etc for an email server or POSTFIX + NGINX
- NOT READY YET
