# Bash Ubuntu Management Scripts

BUMS is a hosting management script, using Bash on Ubuntu.
I have run hosting servers for since 1997, so i have a fair bit of experience.
I have used cPanel, Webmin and others. These hosting panels were all started over 20 years ago, and suffer from being stuck in a rut created at that time.

Problems include:
1. Because email is not separate, when their php website is hacked their email is hacked too.
2. Customers are treated as trusted users, they should not be. Customers should only be given what is needed.
3. Customers are allowed to use passwords, they should be using ssh keys.
4. The panels code is far too complex, they lack a simplistic approach.

BUMS configures a lean efficient and secure system.
Install1.sh uses about 5gb not counting the swap usage you choose.
The full install with 4gb swap uses 10gb.

## Hardware configuration
If you intend to install nginx (install2.sh) you should install quotas. Quotas will stop one user crashing your whole system by using all disk space.
If you intend to install quotas, attaching a disk/partition to your instance and mounting it as /nginx will allow you to install journaled quotas (rather than deprecated quotas). This disk/partition will contain all nginx users websites.

If you intend to install Postfix you might also like to store all email accounts on a seperate disk/partition mounted as /vmail (quotas not usefull). For ease of data recovery all nginx/postfix backups will be stored in /nginx/backups and /vmail/backups.

Using an attached disk will allow you to detach and attach it to another instance.

### Procedure
Using Google Compute as an example... (similar for Amazon and Azure)

Create and attach disk/s.

identify attached disks
> lsblk

I see sdb and sdc disks have no parttition
lets create two partitions on 20gb sdb

set disk features
> parted -a optimal /dev/sdb mklabel gpt

create first partition
> parted /dev/sdb mkpart primary ext4 0% 10GB

create 2nd partition
> parted /dev/sdb mkpart primary ext4 10GB 100%

check your work
> lsblk

create filesystem with label
> mkfs.ext4 -L nginx /dev/sdb2

> mkfs.ext4 -L vmail /dev/sdb1

check labels
> lsblk --fs

all good we just have to mount them now...

***********

I want to install journaled quotas on sdb2 (nginx)

check kernel
> uname -r

our kernel has -gcp on the end so...
> apt install linux-modules-extra-gcp quota

you need *-gcp because the kernel is *.gcp (similar for aws and azure)

because sdb2 is an unmouted filesystem we can
> tune2fs -O quota /dev/sdb2

check
> tune2fs -l /dev/sdb2 | grep -i quota

That's it!

******************
> mkdir /vmail

> mkdir /nginx

vi /etc/fstab
add to bottom

LABEL=nginx     /nginx          ext4    defaults        0 2

LABEL=vmail     /vmail          ext4    defaults        0 2

write and quit
>reboot

check quotas are working
> repquota -s /nginx

##### If you only have the one filesystem then....
> apt install linux-image-extra-virtual quota

vi /etc/fstab

add

,usrquota,grpquota

as so..

LABEL=cloudimg-rootfs   /        ext4   defaults,usrquota,grpquota        0 1

create old deprecated quota files
> quotacheck -cugm /

> reboot

check quotas are working
> repquota -s /

## Installation
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
- execute install1.sh

## What install1.sh does...
- download bashTK (my bash toolkit) and bashTK.sig and verify
- checks you are running ubuntu and at least 22.04
- Checks your SSH, hardens it and encourages you to use keys over passwords.
- runs apt update
- gives opportunity to change hostname and timezone
- adds aliases to update (srvrup) and reboot (srvrboot)
- makes vim default editor with tabs at 2 spaces
- asks how much swap memory you want created
- if UFW (firewall) installed you can allow openssh and enable the firewall
- asks if you want to download and install msmtp-mta (a very lightweight mta)
msmtp-mta is great for a server that wont be receiving emails, just generating them.
Uses include : DNS server, Storage Server, Backup Storage, Database Server, Web Server where Port 25 is blocked, etc
- if you choose yes it will ask if you want to install sysstat, logwatch, rblCheck, sysstatReport, rebootCheck and configure unattended-upgrades to install security updates and email you
- it will verify my scripts and configure everything else.
- offers to download install2 and execute it so you can install Nginx and/or Postfix (if msmtp-mta is not installed).
- or Updates system and reboots. You now have a server ready for you to install DNS, Database, rsync etc

## What install2.sh does
Login as root after reboot
```
cd bums
./
- Check you have run install1.sh
- if msmtp is installed you can install nginx else
- Asks if you want to install just email server or email + web server.
- Web Server option installs and configures Nginx, php-fpm, mariadb and sqlite.
- Email Server option installs and configures Postfix, Dovecot, opendkim, SPF milter
- spam filtering is done at SMTP, no spam tagging.
- no anti-virus, users can install on their own device.
- POP3 only, no quota, cur mail deleted after one day, new mail after 7 days
- also a bunch of cron scripts.

If using an external firewall (most cloud providers do) make sure the following ports are open
80, 443, 25, 587, 995

If you are running msmtp-mta because your provider is blocking port 25 then you need to open 80 and 443.

Allows you to sell mailboxes and on-server aliases
and web hosting (static and PHP) disk space

NOT FINISHED

## User Management Scripts
- coming soon...
