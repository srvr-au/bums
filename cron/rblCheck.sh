#!/bin/bash

vtext='1.00'
usetext='Runs from cron and checks if IP address
is in any RBLs.'

read -r -d '' htext <<-EOF
-------------------------
  Usage: ${0##*/} [options]
  Version: ${vtext}
-------------------------
  [-v]  Output Script Version
  [-h]  Output Help
-------------------------
  Use: ${usetext}
  
EOF

while getopts 'vh' option; do
case "${option}"
in
  v) echo $vtext; exit 1;;
  h) clear; echo "$htext"; exit 1;;
esac
done

ip4=$( hostname -I )
hostname=$( hostname )
email='root'
subject="${hostname} NOT listed in RBL"
emailbody="RBL Check Script Results ${ip4} :\n\n"
count=0
timedout=0
notlisted=0
refused=0

blacklists1='
bl.spamcop.net
b.barracudacentral.org
zen.spamhaus.org
dnsbl-1.uceprotect.net
'
 
blacklists2='
cbl.abuseat.org
dnsbl.sorbs.net
http.dnsbl.sorbs.net
dul.dnsbl.sorbs.net
misc.dnsbl.sorbs.net
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.dnsbl.sorbs.net
web.dnsbl.sorbs.net
zombie.dnsbl.sorbs.net
pbl.spamhaus.org
sbl.spamhaus.org
xbl.spamhaus.org
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
psbl.surriel.com
ubl.unsubscore.com
dyna.spamrats.com
rbl.spamlab.com
spam.spamrats.com
noptr.spamrats.com
cbl.anti-spam.org.cn
cdl.anti-spam.org.cn
dnsbl.inps.de
drone.abuse.ch
httpbl.abuse.ch
korea.services.net
short.rbl.jp
virus.rbl.jp
spamrbl.imp.ch
wormrbl.imp.ch
virbl.bit.nl
rbl.suresupport.com
dsn.rfc-ignorant.org
spamguard.leadmon.net
opm.tornevall.org
netblock.pedantic.org
multi.surbl.org
ix.dnsbl.manitu.net
tor.dan.me.uk
rbl.efnetrbl.org
relays.mail-abuse.org
blackholes.mail-abuse.org
rbl-plus.mail-abuse.org
dnsbl.dronebl.org
access.redhawk.org
db.wpbl.info
rbl.interserver.net
query.senderbase.org
bogons.cymru.com
csi.cloudmark.com
truncate.gbudb.net
'

reverse=$(echo ${ip4} | awk -F. '{print $4"."$3"." $2"."$1}')

process(){
let count++
listed="$(dig +short -t a ${reverse}.${1}.)"
if [ ! -z "$listed" ]; then
case $listed
in
*"timed out"*) let timedout++;;
127.255.255.254 | 127.255.255.255) let refused++;;
*) emailbody+="${1} - [blacklisted] (${listed})\n"
subject="WARNING ${hostname} Listed in RBL Blacklist";;
esac
else
let notlisted++
fi
}

REVERSE_DNS=$(dig +short -x ${ip4})
 
emailbody+="IP ${ip4} NAME ${REVERSE_DNS:----}\n\n"

emailbody+="Important Blacklists:\n\n"
for bl1 in ${blacklists1} ; do
  process $bl1
done

emailbody+="\nOther Blacklists:\n\n"
for bl2 in ${blacklists2} ; do
  process $bl2
done

emailbody+="Total Blacklists checked - ${count}\nTimed Out - ${timedout}\nNot Listed - ${notlisted}\nRefused - ${refused}"
echo -e $emailbody | mail -s "$subject" $email
