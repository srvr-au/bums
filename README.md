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
BUMS allows you to run your servers so your customers do not do stupid things and therefore they will have a trouble free experience.

BUMS configures a lean efficient and secure system. The full install uses 10gb so a 20gb disk is the minimum.

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
- offers to download install2 so you can install Nginx and/or Postfix (if msmtp-mta is not installed).
- Update system and reboot

You now have a server ready for you to install DNS, Database, rsync etc

## Before running install2.sh
If you intend to install nginx you should install quotas. Quotas will stop one user crashing your whole system by using all disk space.
If you intend to install quotas you should attach a disk to your instance and mount it as /nginx. This will contain all nginx users websites. If you intend to install Postfix you might also like to store all email accounts on a seperate disk mounted as /vmail (no quotas). For ease of data recovery all nginx/postfix backups will be stored in /nginx/backups and /vmail/backups.
### Procedure
Using Google Compute as an example...

Create and attach one disk.

If installing quotas install quota modules. First check your kernel
> uname -r

Google Compute will have a kernel with -gcp at the end, aws and azure are similiar.
So you need to install the modules ending in -gcp
Other providers may use generic kernels with no -gcp
> apt install linux-modules-extra-gcp quota quotatool -y

Reboot to load modules in kernel

Once rebooted check for modules
> find /lib/modules/ -type f -name '*quota_v*.ko*'

You should find two v1 and v2

Create partition and file system.
> fdisk -l

Your second disk will probably be named /dev/sdb, third /dev/sdc etc
Partition /dev/sdb
> fdisk /dev/sdb

You will have an input. Enter n return then enter to use defaults. Once partition is created you need to write it. Enter w

Create the filesystem
> mkfs -t ext4 /dev/sdb1

If you wish to use quotas
> tune2fs -O quota /dev/sdb1

Time to mount the disk
> mkdir /nginx

> mount /dev/sdb1 /nginx

If using quota
> quotaon -v /nginx

> quotaon -p

> repquota -s /nginx

Now it is time to edit /etc/fstab so the disks are mounted on reboot
Get sdb1 UUID
> blkid

Add this to /etc/fstab using the actual UUID
> UUID=51444222-wtreyeyey /nginx  ext4  defaults  0 2

Reboot and check everything works. Install2.sh will not attempt to install quotas because it is just too complex.

If you only have one disk, then you cannot use journaled quotas you have to use deprecated quotas. Install modules and quota as above. Then edit /etc/fstab. You need to add `,usrquota,grpquota` to root / filesystem getting something like
> LABEL=cloudimg-rootfs   /        ext4   defaults,usrquota,grpquota        0 1

Reboot and you should be good. No need to turn quotas on the reboot should do that.

## What install2.sh does
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
