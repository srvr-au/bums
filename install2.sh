#!/bin/bash

vtext='1.00'
usetext='This script gives you the option 
  to setup an Email Server Only (No web Server)
  or an Email and Web Server.
  
  The email server comprises Postfix with RBL check,
  SPF check and DKIM. Also Dovecot.
  
  The Web Server comprises Nginx, with MariaDB and PHP.
  
  Automatic free ssl from letsEncrypt.
  
  You do not have the option to setup only Nginx
  as a web server needs a fully fledged MTA.
  '
  
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

clear

if [[ ! -f bashTK ]]; then
  echo 'Please run install1.sh first...'
  exit
fi
rm install1.sh
source bashTK
[[ $( pwd ) != '/root/bums' ]] && BTKfatalError 'You cannot run this script from here.'
BTKisInstalled 'msmtp-mta' && BTKfatalError 'msmtp-mta is installed, you cannot have 2 mtas.'

echo -e "${btkBlu}========================${btkRes}\n${btkBlu}Bash Ubuntu Management Scripts (BUMS)${btkRes}\n${btkBlu}========================${btkRes}\n"
echo -e ${usetext}

BTKpause
BTKheader 'Menu Options'
while true; do
btkMenuOptions=('Email Server Only' 'Email plus Web Server')
BTKmenu 'y' 'Install2 Main Menu'
if [[ $btkMenuAnswer == 'a' ]]; then
  installNginx='n'
  BTKinfo 'Installing Email Services ONLY'
  break
elif [[ $btkMenuAnswer == 'b' ]]; then
  installNginx='y'
  BTKinfo 'Installing Email and Web Services'
  break
else
  BTKinfo 'You did not choose an option, exiting'
  BTKexit
fi
done

BTKpause
BTKheader 'We need your email address, this will be root address.'
BTKaskConfirm 'Please enter your email address...'
[[ $btkAnswer == '' ]] && BTKfatalError 'Sorry we do need an email address'
email=$btkAnswer

mkdir -p /root/bums/ssl/${btkHost}

if [[ installNginx == 'y' ]]; then

BTKpause
BTKheader 'Add sftpgroup, chroot sftpgroup to /home'
groupadd sftpgroup
BTKcmdCheck 'sftpgroup added.'
echo '
Match Group sftpgroup
  X11Forwarding no
  AllowTcpForwarding no
  ChrootDirectory /home
#  ForceCommand internal-sftp -d %u/public_html/ -u 0022
' >> /etc/ssh/sshd_config
BTKcmdCheck 'sftpgroup created and chrooted.'

BTKpause
BTKheader 'Install nginx, php and mariadb'
BTKinfo 'Updating Repositories'
apt update
install=()
install='expect nginx php-fpm php-cli php-common php-gd php-mysql php-mbstring php-json php-sqlite3 php-gnupg php-curl php-zip mariadb-server sqlite3'

BTKpause
BTKheader 'Creating skel directories including html and log files'

mkdir -p /etc/skel/logs/http
touch /etc/skel/logs/http/access.log
touch /etc/skel/logs/http/error.log
mkdir /etc/skel/logs/php
touch /etc/skel/logs/php/access.log
touch /etc/skel/logs/php/error.log
touch /etc/skel/logs/php/mail.log
mkdir /etc/skel/sqlite
mkdir -p /etc/skel/php/opcache
mkdir /etc/skel/php/session
mkdir /etc/skel/php/wsdlcache
mkdir -p /etc/skel/php/tmp/misc
mkdir /etc/skel/php/tmp/uploads

BTKheader 'Placing html files into templates folder'

echo '<!doctype html><html lang="en-au"><head>
<meta name="robots" content="noindex,nofollow,noarchive">
<title>Default Website Page</title>
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta charset="utf-8">

<style type="text/css">
  
*, *:after, *:before {box-sizing: inherit;}
html {box-sizing: border-box;font-size: 120%;line-height:1.5;}
body{font-family:sans-serif;background:#ffffff;margin:0;}

#onlyviewport {height:100vh;overflow:hidden;display:flex;align-items:center;justify-content:center;background-color:#2675B6;background-image:linear-gradient(#2675B6, #D8E9F7 100%);background-repeat:no-repeat;background-attachment:fixed;}
#onlyviewport > div {padding:3vw;text-align:center;border:2px solid #5068B8;background:#ffffff;border-radius:10px;box-shadow:3px 3px 7px #777;width:500px;max-width:80vw;}

</style></head><body>

<div id="onlyviewport"><div>

  <p><b>Default Website Page</b><br>This page can appear when there is no website configured. If you are still seeing it after uploading pages you will need to clear your cache.</p>

</div></div>

</body>
</html>
' > /root/bums/templates/index.html

echo '<!doctype html><html lang="en-au"><head><meta name="robots" content="noindex,nofollow,noarchive"><title>Website Error</title><meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"><meta charset="utf-8">
<style type="text/css">
*, *:after, *:before {box-sizing: inherit;}
html {box-sizing: border-box;font-size: 100%;line-height:1.5;}
body{font-family:sans-serif;background:#ffffff;margin:0;}
#onlyviewport {height:100vh;overflow:hidden;display:flex;align-items:center;justify-content:center;background-color:#2675B6;background-image:linear-gradient(#2675B6, #D8E9F7 100%);background-repeat:no-repeat;background-attachment:fixed;}
#onlyviewport > div {padding:3vw;text-align:center;border:2px solid #5068B8;background:#ffffff;border-radius:10px;box-shadow:3px 3px 7px #777;width:500px;max-width:80vw;}
</style></head><body>
<div id="onlyviewport"><div><p>
<b>Web Server Error <!--# echo var="status" default="" --> - <!--# echo var="status_text" default="Something goes wrong" --></b>
<br>Click to go to our first page: <a href=https://<!--#echo var="HTTP_HOST" --> target="_top"><!--#echo var="HTTP_HOST" --></a>
</p></div></div>
</body>
</html>
' > /root/bums/templates/error.html

BTKpause
BTKheader 'Placing files into /var/www'

mkdir -p /var/www/html/suspended
mkdir -p /var/www/logs/http
touch /var/www/logs/http/error.log
touch /var/www/logs/http/access.log
mkdir /var/www/logs/php
touch /var/www/logs/php/error.log
touch /var/www/logs/php/mail.log
touch /var/www/logs/php/access.log
mkdir -p /var/www/php/tmp/uploads
mkdir /var/www/php/session
mkdir /var/www/php/opcache
mkdir /var/www/php/wsdlcache

echo '<!doctype html><html lang="en-au"><head><meta name="robots" content="noindex,nofollow,noarchive"><title>Website Suspended</title><meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"><meta charset="utf-8">
<style type="text/css">
*, *:after, *:before {box-sizing: inherit;}
html {box-sizing: border-box;font-size: 100%;line-height:1.5;}
body{font-family:sans-serif;background:#ffffff;margin:0;}
#onlyviewport {height:100vh;overflow:hidden;display:flex;align-items:center;justify-content:center;background-color:#2675B6;background-image:linear-gradient(#2675B6, #D8E9F7 100%);background-repeat:no-repeat;background-attachment:fixed;}
#onlyviewport > div {padding:3vw;text-align:center;border:2px solid #5068B8;background:#ffffff;border-radius:10px;box-shadow:3px 3px 7px #777;width:500px;max-width:80vw;}
</style></head><body>
<div id="onlyviewport"><div>
<p><b>Suspended Website - Contact your Hosting Provider</b></p>
</div></div>
</body>
</html>' > /var/www/html/suspended/index.html

echo '<!doctype html><html lang="en-au"><head><meta name="robots" content="noindex,nofollow,noarchive"><title>Server Information</title><meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"><meta charset="utf-8">
<style type="text/css">
*, *:after, *:before {box-sizing: inherit;}
html {box-sizing: border-box;font-size: 100%;line-height:1.5;}
body{font-family:sans-serif;background:#ffffff;margin:0;}
#onlyviewport {height:100vh;overflow:hidden;display:flex;align-items:center;justify-content:center;background-color:#2675B6;background-image:linear-gradient(#2675B6, #D8E9F7 100%);background-repeat:no-repeat;background-attachment:fixed;}
#onlyviewport > div {padding:3vw;text-align:center;border:2px solid #5068B8;background:#ffffff;border-radius:10px;box-shadow:3px 3px 7px #777;width:500px;max-width:80vw;}
</style></head><body>
<div id="onlyviewport"><div>
<p><b>Nginx Server</b></p>
</div></div>
</body>
</html>' > /var/www/html/index.html

cp -v /root/bums/templates/error.html /var/www/html/error.html

BTKpause
BTKheader 'Configure Nginx'

BTKbackupOrigConfig '/etc/nginx/nginx.conf'

tee /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
worker_priority 15; # nice nginx so it doesnt use all resources under high load
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
worker_connections 512;
multi_accept on;
use epoll;
}

http {

# Basic Settings
sendfile on; # on for decent direct disk I/O
tcp_nopush on;
tcp_nodelay on;

# Timeouts, do not keep connections open longer then necessary to reduce
# resource usage and deny Slowloris type attacks.
client_body_timeout 4s; # maximum time between packets the client can pause when sending nginx any data
client_header_timeout 4s; # maximum time the client has to send the entire header to nginx
keepalive_timeout 75s; # timeout which a single keep-alive client connection will stay open
send_timeout 24s; # maximum time between packets nginx is allowed to pause when sending the client data
http2_idle_timeout 120s; # inactivity timeout after which the http2 connection is closed
http2_recv_timeout 4s; # timeout if nginx is currently expecting data from the client but nothing arrives

## Size Limits
client_body_buffer_size 8k;
client_header_buffer_size 1k;
client_max_body_size 1m;
large_client_header_buffers 4 8k;

types_hash_max_size 2048;
server_names_hash_bucket_size 64;

ignore_invalid_headers on;
server_tokens off;
charset utf-8;
reset_timedout_connection on;  # reset timed out connections freeing ram
max_ranges 1; # allow a single range header for resumed downloads and to stop large range header DoS attacks
# server_name_in_redirect off; # if off, nginx will use the requested Host header

include /etc/nginx/mime.types;
default_type application/octet-stream;

#rate limiting
limit_req_zone $binary_remote_addr zone=NOFLOOD:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=WPRATELIMIT:10m rate=2r/s;

# Security related headers
add_header X-Xss-Protection "1; mode=block" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self';";

# SSL Settings
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# Logging Settings
access_log /var/www/logs/http/access.log;
error_log /var/www/logs/http/error.log;

# Gzip Settings
gzip off; # disable on the fly gzip compression due to higher latency, only use gzip_static
#gzip_http_version 1.0; # serve gzipped content to all clients including HTTP/1.0 
gzip_static on;  # precompress content (gzip -1) before uploading
#gzip_vary on;  # send response header "Vary: Accept-Encoding"
gzip_proxied any;  # allows compressed responses for any request even from proxies

# Error Map
map $status $status_text {
  400 'Bad Request';
  401 'Unauthorized';
  402 'Payment Required';
  403 'Forbidden';
  404 'Page Not Found';
  405 'Method Not Allowed';
  406 'Not Acceptable';
  407 'Proxy Authentication Required';
  408 'Request Timeout';
  409 'Conflict';
  410 'Gone';
  411 'Length Required';
  412 'Precondition Failed';
  413 'Payload Too Large';
  414 'URI Too Long';
  415 'Unsupported Media Type';
  416 'Range Not Satisfiable';
  417 'Expectation Failed';
  418 'I am a teapot';
  421 'Misdirected Request';
  422 'Unprocessable Entity';
  423 'Locked';
  424 'Failed Dependency';
  425 'Too Early';
  426 'Upgrade Required';
  428 'Precondition Required';
  429 'Too Many Requests';
  431 'Request Header Fields Too Large';
  451 'Unavailable For Legal Reasons';
  500 'Internal Server Error';
  501 'Not Implemented';
  502 'Bad Gateway';
  503 'Service Unavailable';
  504 'Gateway Timeout';
  505 'HTTP Version Not Supported';
  506 'Variant Also Negotiates';
  507 'Insufficient Storage';
  508 'Loop Detected';
  510 'Not Extended';
  511 'Network Authentication Required';
  default 'Something is wrong';
}

error_page 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 421 422 423 424 425 426 428 429 431 451 500 501 502 503 504 505 506 507 508 510 511 /error.html;

# Virtual Host Configs
include /etc/nginx/conf.d/*.conf;
include /etc/nginx/sites-enabled/*;
}
EOF

BTKinfo 'Install 7g Web Application Firewall'
wget https://raw.githubusercontent.com/srvr-au/bums/main/thirdParty/7g-firewall.conf
mv 7g-firewall.conf /etc/nginx/conf.d/
wget https://raw.githubusercontent.com/srvr-au/bums/main/thirdParty/7g.conf
mv 7g.conf /etc/nginx/snippets/

BTKinfo 'Reload Nginx'
nginx -t
systemctl reload nginx
ufw allow http
ufw allow https

BTKpause
BTKheader 'Installing Hostname SSL Certificate'

curl --silent https://raw.githubusercontent.com/srvrco/getssl/latest/getssl > /root/bums/getssl
chmod 700 /root/bums/getssl

echo 'CA="https://acme-v02.api.letsencrypt.org"
FULL_CHAIN_INCLUDE_ROOT="true"
RENEW_ALLOW="10"
RELOAD_CMD="systemctl reload nginx"
SERVER_TYPE="https"
CHECK_REMOTE="true"
ACCOUNT_KEY_TYPE="secp384r1"
PRIVATE_KEY_ALG="secp384r1"
ACCOUNT_KEY="/root/.getssl/account.key"
ACCOUNT_EMAIL="srvremail"
' > /root/.getssl/getssl.cfg
sed -i "s/srvremail/${email}/" /root/.getssl/getssl.cfg

/root/bums/getssl -c "${btkHost}"

echo 'SANS=""
USE_SINGLE_ACL="true"
ACL=(/var/www/html/.well-known/acme-challenge)
TOKEN_USER_ID="root:root"
DOMAIN_KEY_LOCATION="/root/bums/ssl/srvrdomain/privkey.pem"
DOMAIN_CHAIN_LOCATION="/root/bums/ssl/srvrdomain/fullchain.pem"
DOMAIN_PEM_LOCATION="/root/bums/ssl/srvrdomain/keyfullchain.pem"
RELOAD_CMD=('systemctl reload nginx' 'systemctl reload postfix' 'systemctl reload dovecot')
' > /root/.getssl/${btkHost}/getssl.cfg

sed -i "s/srvrdomain/${btkHost}/g" /root/.getssl/${btkHost}/getssl.cfg

/root/bums/getssl -a

command="/root/bums/getssl -u -a"
job="30 09 * * MON,THU $command"
makecronjob "$command" "$job"

BTKpause
BTKheader 'Setup Nginx server files'

BTKbackupOrigConfig '/etc/nginx/sites-available/default'

echo 'server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /var/www/html/suspended;
  index index.html
  server_name _;
  try_files '' /index.html =404;
}
server {
  listen 443 ssl http2 default_server;
  listen [::]:443 ssl http2 default_server;
  ssl_certificate /root/bums/ssl/srvrdomain/keyfullchain.pem;
  ssl_certificate_key /root/bums/ssl/srvrdomain/keyfullchain.pem;
  ssl_stapling on;
  return 302 http://$host$request_uri;
}
' > /etc/nginx/sites-available/default

sed -i "s/srvrdomain/${btkHost}/g" /etc/nginx/sites-available/default

echo 'server {
server_name www.srvrdomain;
return 301 https://srvrdomain$request_uri;
}

server {
listen 80;
listen [::]:80;
root /var/www/html;
index index.htm index.html index.php;
server_name srvrdomain;
location / {try_files $uri $uri/ =404;}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /var/www/html;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
access_log        off;
log_not_found     off;
expires           30d;
}

# Redirect to https
return 302 https://$host$request_uri;

#80EditTag#

}

server {
listen 443 ssl http2;
listen [::]:443 ssl http2;

ssl_certificate /root/bums/ssl/srvrdomain/keyfullchain.pem;
ssl_certificate_key /root/bums/ssl/srvrdomain/keyfullchain.pem;
ssl_stapling on;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

root /var/www/html;
index index.htm index.html index.php;
server_name srvrdomain;
include /etc/nginx/snippets/7g.conf;
location / {
  try_files $uri $uri/ =404;
  limit_except GET HEAD POST { deny all; }
  limit_req zone=NOFLOOD burst=30 nodelay;
}
location ~ \.php$ {
fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
include fastcgi.conf;
}
location ~ ^/fpm-srvrXXXXX$ {
fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
include fastcgi.conf;
}
location /nginx-srvrXXXXX {
stub_status on;
}
location ~ /\. {
  deny all;
}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /var/www/html;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
access_log        off;
log_not_found     off;
expires           30d;
}

#443EditTag#

}
' > /etc/nginx/sites-available/${btkHost}

sed -i "s/srvrdomain/${btkHost}/g" /etc/nginx/sites-available/${btkHost}
srvrRandom=$( BTKrandLetters 5 )
sed -i "s/srvrXXXXX/${srvrRandom}/g" /etc/nginx/sites-available/${btkHost}

ln -s /etc/nginx/sites-available/${btkHost} /etc/nginx/sites-enabled/${btkHost}.conf

nginx -t

BTKpause
BTKheader 'Creating root php conf files'

BTKbackupOrigConfig '/etc/php/8.1/fpm/php-fpm.conf'

sed -i "s/^;emergency_restart_threshold = 0/emergency_restart_threshold = 10/" /etc/php/8.1/fpm/php-fpm.conf
BTKgrepCheckSOL 'emergency_restart_threshold = 10' '/etc/php/8.1/fpm/php-fpm.conf'

sed -i "s/^;emergency_restart_interval = 0/emergency_restart_interval = 1m/" /etc/php/8.1/fpm/php-fpm.conf
BTKgrepCheckSOL 'emergency_restart_interval = 1m' '/etc/php/8.1/fpm/php-fpm.conf'

sed -i "s/^;process_control_timeout = 0/process_control_timeout = 10s/" /etc/php/8.1/fpm/php-fpm.conf
BTKgrepCheckSOL 'process_control_timeout = 10s' '/etc/php/8.1/fpm/php-fpm.conf'

BTKbackupOrigConfig '/etc/php/8.1/fpm/pool.d/www.conf'

echo '[www]
listen = /run/php/php8.1-fpm.sock
listen.allowed_clients = 127.0.0.1
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
user = www-data
group = www-data
pm = ondemand
pm.max_children = 2
pm.status_path = /fpm-srvrXXXXX
access.log = /var/www/logs/php/access.log

php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
php_admin_value[open_basedir] = /var/www

php_admin_value[memory_limit] = 128M
php_admin_value[max_execution_time] = 90
php_admin_value[max_input_time] = 60
php_admin_value[upload_max_filesize] = 8M
php_admin_value[post_max_size] = 8M
php_admin_value[max_input_vars] = 1000
php_admin_value[expose_php] = false
php_admin_value[smtp_port] = 587
php_admin_value[upload_temp_dir] = /var/www/php/tmp/uploads
php_admin_value[mail.log] = /var/www/logs/php/mail.log
php_admin_value[error_log] = /var/www/logs/php/error.log
php_admin_value[mail.add_x_header] = true
php_admin_value[log_errors] = true

php_value[date.timezone] = Australia/Sydney
php_value[session.cookie_secure] = 1
php_value[session.cookie_samesite] = Strict
php_value[session.cookie_httponly] = 1
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/www/php/session
php_value[soap.wsdl_cache_dir]  = /var/www/php/wsdlcache
php_value[opcache.file_cache]  = /var/www/php/opcache

php_flag[display_errors] = false

env[TMP] = /var/www/php/tmp
env[TMPDIR] = /var/www/php/tmp
env[TEMP] = /var/www/php/tmp

' > /etc/php/8.1/fpm/pool.d/www.conf

sed -i "s/srvrXXXXX/${srvrRandom}/g" /etc/php/8.1/fpm/pool.d/www.conf

php-fpm8.1 -t
BTKpause
systemctl daemon-reload
systemctl reload php8.1-fpm
systemctl reload nginx

echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php
echo 'Check Nginx and php is working at:'
echo "https://${btkHost}/phpinfo.php"
echo 'Nginx info is here:'
echo "https://${btkHost}/nginx-${srvrRandom}"
echo 'PHP info is here:'
echo "https://${btkHost}/fpm-${srvrRandom}"

BTKpause
BTKheader 'Setup logrotate for root and users'

echo '/var/www/logs/*/*.log {
size 1M
copytruncate
dateext
rotate 2
}' > /etc/logrotate.d/srvrrootlogs

echo '/home/*/logs/*/*.log {
size 1M
copytruncate
dateext
rotate 2
}' > /etc/logrotate.d/srvruserlogs

BTKpause
BTKheader 'Make sure nginx and php restart on-failure'

BTKaddRestart 'nginx'
BTKaddRestart 'php8.1-fpm'

BTKpause
BTKheader 'Write tmpl files for GetSSL, Nginx and PHP'
mkdir /root/bums/templates

echo 'SANS="www.srvrdomain"
USE_SINGLE_ACL="true"
ACL=(/home/srvruser/srvrdomain/.well-known/acme-challenge)
TOKEN_USER_ID="srvruser:srvruser"
DOMAIN_KEY_LOCATION="/root/bums/ssl/srvrdomain/privkey.pem"
DOMAIN_CHAIN_LOCATION="/root/bums/ssl/srvrdomain/fullchain.pem"
DOMAIN_PEM_LOCATION="/root/bums/ssl/srvrdomain/keyfullchain.pem"
' > /root/bums/templates/getssl.tmpl

echo '[srvruser]
listen = /run/php/php8.1-fpm-srvruser.sock
listen.allowed_clients = 127.0.0.1
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
user = srvruser
group = srvruser
pm = ondemand
pm.max_children = 2
pm.status_path = /fpm-srvrXXXXX
access.log = /home/srvruser/logs/php/access.log

php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
php_admin_value[open_basedir] = /home/srvruser

php_admin_value[memory_limit] = 128M
php_admin_value[max_execution_time] = 90
php_admin_value[max_input_time] = 60
php_admin_value[upload_max_filesize] = 8M
php_admin_value[post_max_size] = 8M
php_admin_value[max_input_vars] = 1000
php_admin_value[expose_php] = false
php_admin_value[smtp_port] = 587
php_admin_value[upload_temp_dir] = /home/srvruser/php/tmp/uploads
php_admin_value[mail.log] = /home/srvruser/logs/php/mail.log
php_admin_value[error_log] = /home/srvruser/logs/php/error.log
php_admin_value[mail.add_x_header] = true
php_admin_value[log_errors] = true

php_value[date.timezone] = Australia/Sydney
php_value[session.cookie_secure] = 1
php_value[session.cookie_samesite] = Strict
php_value[session.cookie_httponly] = 1
php_value[session.save_handler] = files
php_value[session.save_path]    = /home/srvruser/php/session
php_value[soap.wsdl_cache_dir]  = /home/srvruser/php/wsdlcache
php_value[opcache.file_cache]  = /home/srvruser/php/opcache

php_flag[display_errors] = false

env[TMP] = /home/srvruser/php/tmp
env[TMPDIR] = /home/srvruser/php/tmp
env[TEMP] = /home/srvruser/php/tmp

' > /root/bums/templates/phpuser.tmpl

echo 'server {
listen 80;
listen [::]:80;
root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;

access_log /home/srvruser/logs/http/access.log;
error_log /home/srvruser/logs/http/error.log;

location / {try_files $uri $uri/ =404;}

location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

#80EditTag#

}

' > /root/bums/templates/80.tmpl

echo 'server {
  server_name www.srvrdomain;
  return 301 https://srvrdomain$request_uri;
}

server {
listen 80;
listen [::]:80;
root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;
location / {try_files $uri $uri/ =404;}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

# Redirect to https
return 302 https://$host$request_uri;

#80EditTag#

}

server {
listen 443 ssl http2;
listen [::]:443 ssl http2;

ssl_certificate /root/bums/ssl/srvrdomain/fullchain.pem;
ssl_certificate_key /root/bums/ssl/srvrdomain/privkey.pem;
ssl_stapling on;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;
include /etc/nginx/snippets/7g.conf;
location / {
  try_files $uri $uri/ =404;
  limit_except GET HEAD POST { deny all; }
  limit_req zone=NOFLOOD burst=30 nodelay;
}
location ~ \.php$ {
  fastcgi_pass unix:/run/php/php8.1-fpm-srvruser.sock;
  include fastcgi.conf;
}
location ~ ^/fpm-srvrXXXXX$ {
  fastcgi_pass unix:/run/php/php8.1-fpm-srvruser.sock;
  include fastcgi.conf;
}
location /nginx-srvrXXXXX {
  stub_status on;
}
location ~ /\. {
  deny all;
}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

#443EditTag#

}
' > /root/bums/templates/80443php.tmpl

echo 'server {
  server_name www.srvrdomain;
  return 301 https://srvrdomain$request_uri;
}

server {
listen 80;
listen [::]:80;
root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;
location / {try_files $uri $uri/ =404;}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

# Redirect to https
return 302 https://$host$request_uri;

#80EditTag#

}

server {
listen 443 ssl http2;
listen [::]:443 ssl http2;

ssl_certificate /root/bums/ssl/srvrdomain/fullchain.pem;
ssl_certificate_key /root/bums/ssl/srvrdomain/privkey.pem;
ssl_stapling on;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;
include /etc/nginx/snippets/7g.conf;
location / {
  try_files $uri $uri/ =404;
  limit_except GET HEAD POST { deny all; }
  limit_req zone=NOFLOOD burst=30 nodelay;
  # enable permalinks
  try_files $uri $uri/ /index.php?$args;
}
location ~ \.php$ {
  fastcgi_pass unix:/run/php/php8.1-fpm-srvruser.sock;
  include fastcgi.conf;
}
location ~ ^/fpm-srvrXXXXX$ {
  fastcgi_pass unix:/run/php/php8.1-fpm-srvruser.sock;
  include fastcgi.conf;
}
location /nginx-srvrXXXXX {
  stub_status on;
}
location ~ /\. {
  deny all;
}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

# wordpress specific
location ~* /xmlrpc.php$ {
  deny all;
  access_log off;
  log_not_found off;
  return 444;
}
location ~* /(?:uploads|files|wp-content|wp-includes)/.*.php$ {
  deny all;
  access_log off;
  log_not_found off;
}
location ~ \wp-login.php$ {
  limit_req zone=WPRATELIMIT burst=4 nodelay;
}
# Deny public access to wp-config.php
location ~* wp-config.php {
  deny all;
}

#443EditTag#

}
' > /root/bums/templates/80443wp.tmpl

echo 'server {
  server_name www.srvrdomain;
  return 301 https://srvrdomain$request_uri;
}

server {
listen 80;
listen [::]:80;
root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;
location / {try_files $uri $uri/ =404;}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

# Redirect to https
return 302 https://$host$request_uri;

#80EditTag#

}

server {
listen 443 ssl http2;
listen [::]:443 ssl http2;

ssl_certificate /root/bums/ssl/srvrdomain/fullchain.pem;
ssl_certificate_key /root/bums/ssl/srvrdomain/privkey.pem;
ssl_stapling on;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

root /home/srvruser/srvrdomain;
index index.htm index.html index.php;
server_name srvrdomain;
include /etc/nginx/snippets/7g.conf;
location / {
  try_files $uri $uri/ =404;
  limit_except GET HEAD POST { deny all; }
  limit_req zone=NOFLOOD burst=30 nodelay;
}
location /nginx-srvrXXXXX {
  stub_status on;
}
location ~ /\. {
  deny all;
}
location = /error.html {
  ssi on;
  internal;
  auth_basic off;
  root /home/srvruser/srvrdomain;
}

# Browser Caching
location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|flv|swf|ttf|eot|svg|woff)$ {
  access_log        off;
  log_not_found     off;
  expires           30d;
}

#443EditTag#

}
' > /root/bums/templates/80443.tmpl

echo 'location ~ \.php$ {
  fastcgi_pass unix:/run/php/php8.1-fpm-srvruser.sock;
  include fastcgi.conf;
}
location ~ ^/fpm-srvrXXXXX$ {
  fastcgi_pass unix:/run/php/php8.1-fpm-srvruser.sock;
  include fastcgi.conf;
}
' > /root/bums/templates/addphp.tmpl

BTKpause
BTKheader 'Secure MariaDB'
BTKinfo 'We will secure root access using unix_socket rather than root password.'
echo 'Working... Please wait'

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none): \"
send \"\r\"
expect \"Enable unix_socket authentication \[Y/n\] \"
send \"y\r\"
expect \"Set root password? \[Y/n\] \"
send \"n\r\"
expect \"Remove anonymous users? \[Y/n\] \"
send \"y\r\"
expect \"Disallow root login remotely? \[Y/n\] \"
send \"y\r\"
expect \"Remove test database and access to it? \[Y/n\] \"
send \"y\r\"
expect \"Reload privilege tables now? \[Y/n\] \"
send \"y\r\"
expect eof
")
echo 'Done!'
BTKinfo 'If no errors it was a success!'

BTKpause
BTKheader 'Install wp cli for Wordpress Management'
https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
wp --info

BTKpause
BTKheader 'Install Quota for Nginx users'
BTKinfo 'We will install quota on root partition. We will install old-style rather than journaled quotas. If you wish to use journaled quotas you need to use tune2fs -O quota /dev/sdb1 on unmounted partition. Not possible if you have only root partition. We will use the journaled format... because we can.'

BTKask 'Shall we install quotas for nginx users...'
if [[ "$btkYN" == 'y' ]]; then
  install=()
  install='linux-image-extra-virtual quota'
  BTKinstall ${install[@]}
  BTKpause
  
  sed -r -i'.bak' 's#(/\s.*defaults)\s#\1,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv1 #' /etc/fstab
  mount -o remount /
  quotacheck -cugm /
  quotaon -v /
  cat /proc/mounts | grep ' / '
  systemctl daemon-reload
  repquota -s /
else
  echo 'No quotas for you then...'
fi

BTKsuccess 'Thats Nginx, php and mysql ready for action!'

fi

BTKpause
BTKheader 'Install Postfix, Dovecot, opendkim'
BTKinfo 'Updating Repositories'
apt update
install=()
install='s-nail postfix postfix-cdb postfix-policyd-spf-python opendkim opendkim-tools dovecot-core dovecot-pop3d'
BTKask 'Would you like to install logwatch... ?'
[[ ${btkYN} == 'y' ]] && install+=('logwatch') || echo 'No Logwatch for you then...'
BTKask 'Would you like to install sysstat (System Statistics)... ?'
[[ ${btkYN} == 'y' ]] && install+=('sysstat') || echo 'No sysstat for you then...'
BTKask 'Would you like to install Postfix Log Summary (Y)... ?'
[[ ${btkYN} == 'y' ]] && install+=('pflogsumm') || echo 'No Postfix Log Summary for you then...'
echo -e "We will try to install the following software\n${install[@]}\n"
BTKpause

BTKinstall ${install[@]}

BTKpause
BTKheader 'Configure s-nail and aliases'
ln -s /usr/bin/s-nail /usr/bin/mail
BTKcmdCheck 'link s-nail to mail command.'
echo "root: $email
postmaster: root
webmaster: root
hostmaster:root
abuse: root
mailer-daemon: root
default: root
" > /etc/aliases
BTKcmdCheck 'Write root email address into aliases file.'

BTKpause
BTKheader 'Configure Postfix'

mkdir /etc/skelempty
BTKcmdCheck 'Add empty skel for vmail user'
mkdir /home2
BTKcmdCheck 'Add /home2 for vmail'

echo 'DSHELL=/usr/sbin/nologin
DHOME=/home2
GROUPHOMES=no
LETTERHOMES=no
SKEL=/etc/skelempty

FIRST_SYSTEM_UID=100
LAST_SYSTEM_UID=999

FIRST_SYSTEM_GID=100
LAST_SYSTEM_GID=999

FIRST_UID=1000
LAST_UID=59999

FIRST_GID=1000
LAST_GID=59999

USERGROUPS=yes
USERS_GID=100
DIR_MODE=0750
SETGID_HOME=no
QUOTAUSER=""
SKEL_IGNORE_REGEX="dpkg-(old|new|dist|save)"
' > /etc/adduser2.conf
BTKcmdCheck 'Add vmail skel conf.'

adduser --uid 20000 --disabled-password --disabled-login --conf /etc/adduser2.conf --gecos '' vmail
usermod -aG vmail postfix
usermod -aG vmail dovecot
BTKcmdCheck 'Add vmail user'

BTKbackupOrigConfig '/etc/postfix/main.cf'

echo 'compatibility_level = 3.6
myhostname = srvrhost
myorigin = $myhostname
inet_interfaces = all
inet_protocols = all
mydestination = $myhostname, localhost
mynetworks_style = host
biff = no
append_dot_mydomain = no

smtpd_banner = $myhostname ESMTP
smtpd_helo_required = yes
tls_ssl_options = NO_RENEGOTIATION
tls_preempt_cipherlist = yes

# to this server
smtpd_tls_security_level = may
smtpd_tls_chain_files = /root/bums/ssl/srvrhost/keyfullchain.pem
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtpd_tls_received_header = yes

smtpd_tls_ciphers = high
smtpd_tls_mandatory_protocols = >=TLSv1.2
smtpd_tls_protocols = >=TLSv1.2
smtpd_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtpd_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtpd_tls_loglevel = 2

# from this server
smtp_tls_security_level = may
smtp_tls_chain_files = /root/bums/ssl/srvrhost/keyfullchain.pem
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

smtp_tls_ciphers = high
smtp_tls_mandatory_protocols = >=TLSv1.2
smtp_tls_protocols = >=TLSv1.2
smtp_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtp_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtp_tls_loglevel = 2

alias_maps = hash:/etc/aliases
message_size_limit = 10485760
mailbox_size_limit = 1073741824

# These are used to limit clients to 200 emails per day.
anvil_rate_time_unit = 1d
smtpd_client_connection_rate_limit = 200
smtpd_client_message_rate_limit = 200
smtpd_client_recipient_rate_limit = 200
smtpd_client_event_limit_exceptions = 

# Limit emails sent to single domains such as google or yahoo
smtp_destination_concurrency_limit = 2
smtp_destination_rate_delay = 1s
smtp_extra_recipient_limit = 10

# configure postscreen
# Exclude broken clients by whitelisting. Clients in mynetworks
# should always be whitelisted.
postscreen_access_list = permit_mynetworks
postscreen_dnsbl_threshold = 1
postscreen_dnsbl_sites = zen.spamhaus.org
    bl.spamcop.net
    b.barracudacentral.org
    dnsbl-1.uceprotect.net
postscreen_greet_action = enforce
postscreen_dnsbl_action = enforce

smtputf8_enable = no
virtual_mailbox_domains = /etc/postfix/vdomains
virtual_mailbox_base = /home2/vmail
virtual_mailbox_maps = cdb:/etc/postfix/vmailbox
virtual_alias_maps = cdb:/etc/postfix/valias
virtual_uid_maps = static:20000
virtual_gid_maps = static:20000

smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
# A more sophisticated policy allows plaintext mechanisms, but only over a TLS-encrypted connection
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous
# To offer SASL authentication only after a TLS-encrypted session has been established
smtpd_tls_auth_only = yes
# To report SASL login names in Received: message headers
smtpd_sasl_authenticated_header = yes
smtpd_sasl_local_domain = $myhostname

policy-spf_time_limit = 3600s

smtpd_client_restrictions = 
  reject_unknown_client_hostname
  sleep 1, reject_unauth_pipelining
  
smtpd_recipient_restrictions =
  permit_mynetworks
  permit_sasl_authenticated
  check_policy_service unix:private/policy-spf
  permit_auth_destination
  reject

smtpd_helo_restrictions =
  permit_mynetworks
  permit_sasl_authenticated
  reject_invalid_helo_hostname
  reject_non_fqdn_helo_hostname
  reject_unknown_helo_hostname

smtpd_sender_restrictions =
  permit_mynetworks
  permit_sasl_authenticated
  reject_non_fqdn_sender
  reject_unknown_client_hostname
  reject_unknown_sender_domain

smtpd_relay_restrictions = 
  permit_mynetworks
  permit_sasl_authenticated
  permit_auth_destination
  reject_unauth_destination 
  reject

# opendkim Milter configuration
milter_default_action = accept
milter_protocol = 6
smtpd_milters = local:opendkim/opendkim.sock
non_smtpd_milters = $smtpd_milters
' > /etc/postfix/main.cf

sed -i "s/srvrhost/${btkHost}/g" '/etc/postfix/main.cf'
BTKgrepCheck "${btkHost}" '/etc/postfix/main.cf'

touch /etc/postfix/vdomains
BTKcmdCheck 'Create Virtual Domains list'
touch /etc/postfix/vmailbox
BTKcmdCheck 'Create Virtual Mailbox map'
postmap cdb:/etc/postfix/vmailbox
BTKcmdCheck 'Create Virtual Mailbox DB'
touch /etc/postfix/valias
BTKcmdCheck 'Create Virtual Alias map'
postmap cdb:/etc/postfix/valias
BTKcmdCheck 'Create Virtual alias DB'
newaliases

BTKbackupOrigConfig '/etc/postfix/master.cf'

echo '#smtp      inet  n       -       n       -       -       smtpd
smtp      inet  n       -       n       -       1       postscreen
smtpd     pass  -       -       n       -       -       smtpd
  -o syslog_name=postfix/smtp
dnsblog   unix  -       -       n       -       0       dnsblog
tlsproxy  unix  -       -       n       -       0       tlsproxy
submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_reject_unlisted_recipient=no
  -o milter_macro_daemon_name=ORIGINATING
# port 465 not needed anymore
#smtps     inet  n       -       n       -       -       smtpd
#  -o syslog_name=postfix/smtps
#  -o smtpd_tls_wrappermode=yes
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_tls_auth_only=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_relay_restrictions=$mua_relay_restrictions
#628       inet  n       -       n       -       -       qmqpd
pickup    unix  n       -       n       60      1       pickup
cleanup   unix  n       -       n       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
#qmgr     unix  n       -       n       300     1       oqmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
rewrite   unix  -       -       n       -       -       trivial-rewrite
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce
trace     unix  -       -       n       -       0       bounce
verify    unix  -       -       n       -       1       verify
flush     unix  n       -       n       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       n       -       -       smtp
relay     unix  -       -       n       -       -       smtp
        -o syslog_name=postfix/$service_name
        -o smtp_helo_timeout=5
        -o smtp_connect_timeout=5
showq     unix  n       -       n       -       -       showq
error     unix  -       -       n       -       -       error
retry     unix  -       -       n       -       -       error
discard   unix  -       -       n       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
policy-spf  unix  -       n       n       -       -       spawn
     user=nobody argv=/usr/bin/policyd-spf
' > /etc/postfix/master.cf

BTKbackupOrigConfig '/etc/postfix-policyd-spf-python/policyd-spf.conf'

echo 'debugLevel = 1
TestOnly = 1

HELO_reject = Fail
Mail_From_reject = Fail
No_Mail = True
PermError_reject = True
TempError_Defer = True

skip_addresses = 127.0.0.0/8,::ffff:127.0.0.0/104,::1
' > /etc/postfix-policyd-spf-python/policyd-spf.conf

BTKpause
BTKheader 'Configure opendkim'

gpasswd -a postfix opendkim
BTKcmdCheck 'Add postfix user to opendkim group'

backuporigconfig '/etc/opendkim.conf'

selector="${btkHost//./-}"

echo "Syslog                  yes
UMask                   007
Canonicalization       relaxed/simple
# mode can be s (send) or sv (send verify)
Mode                   sv
SubDomains             yes
AlwaysAddARHeader   yes
AutoRestart         yes
AutoRestartRate     10/1M
Background          yes
DNSTimeout          5
SignatureAlgorithm  rsa-sha256
Socket    local:/var/spool/postfix/opendkim/opendkim.sock
PidFile               /run/opendkim/opendkim.pid
OversignHeaders         From
TrustAnchorFile       /usr/share/dns/root.key
UserID                opendkim

# One key for all domains
Domain *
KeyFile /etc/opendkim/keys/${selector}.private
Selector default

# Map domains in From addresses to keys used to sign messages
#KeyTable           refile:/etc/opendkim/key.table
#SigningTable       refile:/etc/opendkim/signing.table

# Hosts to ignore when verifying signatures
ExternalIgnoreList  /etc/opendkim/trusted.hosts

# A set of internal hosts whose mail should be signed
InternalHosts       /etc/opendkim/trusted.hosts
" > /etc/opendkim.conf

mkdir -p /etc/opendkim/keys
chown -R opendkim:opendkim /etc/opendkim
chmod go-rw /etc/opendkim/keys

#echo "*@${hostname} default._domainkey.${hostname}" > /etc/opendkim/signing.table
#echo "default._domainkey.${hostname} ${hostname}:default:/etc/opendkim/keys/${hostname}/default.private" > /etc/opendkim/key.table

echo "127.0.0.1
localhost
${btkHost}
" > /etc/opendkim/trusted.hosts

#mkdir /etc/opendkim/keys/${hostname}
#BTKcmdCheck 'make keys directory'

opendkim-genkey -b 1024 -D /etc/opendkim/keys/ -s ${selector} -v
BTKcmdCheck 'make key for opendkim'

chown opendkim:opendkim /etc/opendkim/keys/${selector}.private
BTKcmdCheck 'chown keyfile'

mkdir /var/spool/postfix/opendkim
BTKcmdCheck 'create opendkim dir in postfix spool'
chown opendkim:postfix /var/spool/postfix/opendkim
BTKcmdCheck 'chown dir in spool'

if [[ installNginx == 'n' ]]; then
BTKpause
BTKheader 'Install Certbot from Snap'
snap install core
snap refresh core
snap install --classic certbot
BTKcmdCheck 'Certbot installation'
BTKpause
BTKheader 'Installing Hostname SSL Certificate'
mkdir /root/bums/helpers
touch /root/bums/helpers/certbotDeployHook.sh
tee -a /root/bums/helpers/certbotDeployHook.sh <<'EOF'
#!/bin/bash

hostname=$( hostname )
email='root'
sslDir="/etc/letsencrypt/live/${hostname}/"
cat ${sslDir}privkey.pem > ${sslDir}keyfullchainTmp.pem
cat ${sslDir}fullchain.pem >> ${sslDir}keyfullchainTmp.pem
cp ${sslDir}keyfullchainTmp.pem ${sslDir}keyfullchain.pem
if [[ $? -eq 0 ]]; then
  rm ${sslDir}keyfullchainTmp.pem
  systemctl reload postfix dovecot
else
  emailbody="Command\n"
  emailbody+="cp ${sslDir}keyfullchainTmp.pem ${sslDir}keyfullchain.pem"
  emailbody+="\nDid not work..."
  echo -e "$emailbody" | mail -s "Certbot Error" $email
fi
EOF
chmod +x /root/bums/helpers/certbotDeployHook.sh
certbot certonly --standalone --agree-tos --non-interactive -m $email -d ${btkHost} --deploy-hook "/root/bums/helpers/certbotDeployHook.sh" --pre-hook "ufw allow 80" --post-hook "ufw delete allow 80"
fi

BTKpause
BTKheader 'Enable opendkim and postfix'
BTKenable opendkim
BTKenable postfix
BTKaddRestart opendkim
BTKaddRestart postfix

mail -s "Public Key" $email < /etc/opendkim/keys/${selector}.txt
BTKcmdCheck 'public key mailed'

BTKpause
BTKheader 'Lets configure some scripts'
if BTKisInstalled 'pflogsumm'; then
  command="perl /usr/sbin/pflogsumm -e -d yesterday /var/log/mail.log | mail -s \"${btkHost} Postfix Log\" root"
  job="00 07 * * * $command"
  BTKmakeCron "$command" "$job"
fi
if BTKisInstalled 'sysstat'; then
  echo 'Just enabling sysstat'
  BTKenable 'sysstat'
  BTKgetStatus 'sysstat'
  BTKpause
fi

BTKinfo 'Please wait while I grab a needed file...'
  if wget https://raw.githubusercontent.com/srvr-au/bashTK/main/installHelper.sh &&
    wget https://raw.githubusercontent.com/srvr-au/bashTK/main/installHelper.sig &&
    gpg --verify installHelper.sig installHelper.sh; then
    BTKsuccess 'File downloaded and verified...'
    rm installHelper.sig
    chmod +x installHelper.sh
    BTKcmdCheck 'chmod installHelper.sh executable'
  else
    BTKfatalError 'A needed file failed to download or verify'
  fi
BTKpause
  
./installHelper.sh

BTKpause
BTKheader 'Configure Dovecot'
BTKbackupOrigConfig '/etc/dovecot/dovecot.conf'

echo '#mail_debug = yes
auth_mechanisms = plain
first_valid_uid = 1000
mail_location = maildir:/home2/vmail/%u

protocols = pop3
pop3_fast_size_lookups = yes
pop3_lock_session = yes

ssl = required
ssl_cert = </root/bums/ssl/srvrhost/keyfullchain.pem
ssl_key = </root/bums/ssl/srvrhost/keyfullchain.pem
ssl_min_protocol = TLSv1.2
ssl_prefer_server_ciphers = yes

service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0666
    user = postfix
  }
}

service pop3-login {
  inet_listener pop3 {
    port = 0
  }
}

passdb {
  args = scheme=SHA256-CRYPT username_format=%u /etc/dovecot/users
  driver = passwd-file
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/home2/vmail/%u
}
' > /etc/dovecot/dovecot.conf

sed -i "s/srvrhost/${btkHost}/g" /etc/dovecot/dovecot.conf

touch /etc/dovecot/deny.pop3
BTKfileExists '/etc/dovecot/deny.pop3'
touch /etc/dovecot/users
BTKfileExists '/etc/dovecot/users'
touch /etc/dovecot/usernames
BTKfileExists '/etc/dovecot/usernames'

systemctl reload dovecot

ufw allow 25/tcp
ufw limit 587/tcp,995/tcp

command="doveadm expunge -F /etc/dovecot/usernames mailbox '*' NEW savedbefore 7d"
job="15 07 * * * $command"
BTKmakeCron "$command" "$job"

command="doveadm expunge -F /etc/dovecot/usernames mailbox '*' SEEN savedbefore 1d"
job="45 07 * * * $command"
BTKmakeCron "$command" "$job"

tee /root/bums/cron/getUsage.sh <<'EOF' >/dev/null
#!/bin/bash

vtext='1.00'
usetext='Runs from cron and emails disk usage
of /home and /home2'

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

hostname=$( hostname )
email='root'
now=$( date )

message="$hostname Disk Usage Report at $now\n"
message+="\n            Total Used Free\n"
message+="Disk Space: $( df -h | grep -w / | awk '{ print $2" "$3" "$4 }' )"
message+="\n\nWeb Disk Usage /home\n"
message+=$( du -h --max-depth=2 /home )
message+="\n\nEmail Disk Usage /home2\n"
message+=$( du -h --max-depth=2 /home2 )

echo -e "$message" | mail -s "$hostname Disk Usage" $email
EOF

chmod +x /root/bums/cron/getUsage.sh

command="/root/bums/cron/getUsage.sh > /dev/null 2>&1"
job="00 08 * * * $command"
BTKmakeCron "$command" "$job"

BTKheader 'Time to reboot'
BTKpause
systemctl reboot
