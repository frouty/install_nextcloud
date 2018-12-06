#!/bin/sh

echo "Install nextcloud"
echo "Let's go..."

pkg update

## install package for easy use of jail
pkg install git emacs tree wget zsh powerline-fonts pgpgpg


## install package for nextcloud
pkg install nginx mariadb103-server redis php72-bz2 php72-ctype php72-curl php72-dom php72-exif php72-fileinfo php72-filter php72-gd php72-hash php72-iconv php72-intl php72-json php72-mbstring php72-pecl-mcrypt php72-pdo_mysql php72-openssl php72-posix php72-session php72-simplexml php72-xml php72-xmlreader php72-xmlwriter php72-xsl php72-wddx php72-zip php72-zlib php72-opcache

## mkdir /root/tmp
mkdir /root/tmp
TEMP="/root/tmp"

portsnap fetch extract
make config-recursive install -C /usr/ports/databases/pecl-redis
make config-recursive install -C /usr/ports/devel/pecl-APCu

sysrc 'nginx_enable=YES' 
sysrc 'php_fpm_enable=YES' 
sysrc 'mysql_enable=YES' 
sysrc 'redis_enable=YES'
# ou
# sysrc {ntpdate,nginx,postgresql,php_fpm}_enable=YES
#sysrc {ntpdate,nginx,mysql,php_fpm}_enable=YES j'ai pas l'impression que cela marche
sysrc 'ntpdate_enable=YES'
sysrc 'ntpdate_hosts=0.oceania.pool.ntp.org'

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

echo -e "\n ---- create the /usr/local/etc/nginx/nginx.conf file ----"
cat >  $TEMP/nginx.conf << 'EOF'
worker_processes 2;

events {
     worker_connections  1024;
 }

 http {
     include      mime.types;
     default_type  application/octet-stream;
     sendfile        off;
     keepalive_timeout  65;
     gzip off;

     server {
         root /usr/local/www;
         location = /robots.txt { allow all; access_log off; log_not_found off; }
         location = /nextcloud/core/img/favicon.ico { access_log off; log_not_found off; }
         location ^~ /nextcloud {s
             error_page 403 /nextcloud/core/templates/403.php;
             error_page 404 /nextcloud/core/templates/404.php;
             location /nextcloud {
                 rewrite ^ /nextcloud/index.php$request_uri;
             }
             location ~ ^/nextcloud/(?:build|tests|config|lib|3rdparty|templates|data)/ {
                 deny all;
             }
             location ~ ^/nextcloud/(?:\.|autotest|occ|issue|indie|db_|console) {
                 deny all;
             }
             location ~ ^/nextcloud/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
                 fastcgi_split_path_info ^(.+\.php)(/.*)$;
                 include fastcgi_params;
                 fastcgi_pass unix:/var/run/php-fpm.sock;
                 fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                 fastcgi_param PATH_INFO $fastcgi_path_info;
                 fastcgi_param front_controller_active true;
                 fastcgi_intercept_errors on;
             }
             location ~* \.(?:css|js|woff|svg|gif)$ {
                 try_files $uri /nextcloud/index.php$request_uri;
                 add_header Cache-Control max-age=15778463;
             }
             location ~* \.(?:png|html|ttf|ico|jpg|jpeg)$ {
                 try_files $uri /nextcloud/index.php$request_uri;
             }

         }
     }
 }
EOF
cp $TEMP/nginx.conf /usr/local/etc/nginx/

# replace the relevant lines in /usr/local/etc/php.ini
#cgi.fix_pathinfo=0				\
#date.timezone = America/Los_Angeles		\
#apc.enable_cli=1
PHPINI="/usr/local/etc/php.ini"
echo "\n ---- set variable path to php.ini : ${PHPINI} ----"
#sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(cgi.fix_pathinfo *=).*|\2"0"|g' $PHPINI
#sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(date.timezone *=).*|\2"Pacific/Noumea"|g' $PHPINI

if grep cgi.fix_pathinfo $PHPINI;
then
    sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(cgi.fix_pathinfo *=).*|\2"0"|g' $PHPINI
else
    echo 'cgi.fix_pathinfo=0' >> $PHPINI
fi

if grep date.timezone $PHPINI;
then
    sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(date.timezone *=).*|\2"Pacific/Noumea"|g' $PHPINI
else
    echo 'ate.timezone = Pacific/Noumea' >> $PHPINI
fi

if  grep apc.enable_cli $PHPINI;
then
    echo "hello I found apc.enable_cli"
    sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(apc.enable_cli *=).*|\2"1"|g' $PHPINI  
else
    echo "Ooops I don't find it"
    echo 'apc.enable_cli=1' >> $PHPINI
fi     


## replace the relevant lines in /usr/local/etc/php-fmp.d/wwww.conf
#listen = /var/run/php-fpm.sock
#listen.owner = www
#listen.group = www
#env[PATH] = /usr/local/bin:/usr/bin:/bin 
# toutes ces lignes existent et seule la premiere est  a modifier

WWWCONF="/usr/local/etc/php-fpm.d/www.conf"

sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(listen *=).*|\2"/var/run/php-fpm.sock"|g' $WWWCONF
sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(listen.owner *=).*|\2"www"|g' $WWWCONF
sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(listen.group *=).*|\2"www"|g' $WWWCONF
sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(env[PATH] *=).*|\2"/usr/local/bin:/usr/bin:/bin"|g' $WWWCONF



## /usr/local/etc/my.cnf
# je ne trouve pas ce fichier
#[server]
#skip-networking
#skip-name-resolve
#expire_logs_days = 1
#innodb_flush_method = O_DIRECT
#skip-innodb_doublewrite
#innodb_flush_log_at_trx_commit = 2
#innodb_file_per_table
cat >  $TEMP/my.cnf << 'EOF'
[server]
skip-networking
skip-name-resolve
expire_logs_days = 1
innodb_flush_method = O_DIRECT
skip-innodb_doublewrite
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table
EOF
cp $TEMP/my.cnf /usr/local/etc/

## Replace /add the relevant lines in /usr/local/etc/redis.conf
#port 0
#unixsocket /tmp/redis.sock
#unixsocketperm 777
# le fichier existe.
REDISCONF="/usr/local/etc/redis.conf"
sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(\<port\>)( *).*|\2 0|' $REDISCONF
sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(\<unixsocket\>)( *).*|\2 /tmp/redis.sock|' $REDISCONF
sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(\<unixsocketperm\>)( *).*|\2 777|' $REDISCONF




## installation de nextcloud

NCRELEASE="14.0.4"
cd $TEMP
echo "set the last release of nextcloud to $NCRELEASE"
fetch https://download.nextcloud.com/server/releases/nextcloud-$NCRELEASE.tar.bz2
fetch https://download.nextcloud.com/server/releases/nextcloud-$NCRELEASE.tar.bz2.sha256
fetch https://download.nextcloud.com/server/releases/nextcloud-$NCRELEASE.tar.bz2.asc
fetch https://nextcloud.com/nextcloud.asc

# verify integrity
# cd path to where is download nextcloud
echo "Verify integrity"
shasum -a 256 -c nextcloud-14.0.4.tar.bz2.sha256 < nextcloud-14.0.4.tar.bz2

#verify authenticity
echo "Verify authenticity"
gpg --import nextcloud.asc                                                           
gpg --verify nextcloud-$NCRELEASE.tar.bz2.asc nextcloud-$NCRELEASE.tar.bz2

#
# cd path where you download nextcloud
tar -jxf $TEMP/nextcloud-$NCRELEASE.tar.bz2 -C /usr/local/www
# rm nextcloud-$NCRELEASE.tar.bz2
chown -R www:www /usr/local/www/nextcloud /mnt/files

service nginx start && service php-fpm start && service mysql-server start && service redis start
exit 1
# mysql -e "CREATE DATABASE owncloud;"
# mysql -e "GRANT ALL PRIVILEGES ON owncloud.* TO 'ocuser'@'localhost' IDENTIFIED BY 'ocpass';"
# mysql -e "FLUSH PRIVILEGES;"
# mysql_secure_installation

# service mysql-server start
# mysql_secure_installation
# add a root and password user
# log to mysql -u root -
# create nextcloud database, et nexcloud user.
#CREATE DATABASE nextcloud; 
#CREATE USER 'datamanager'@'localhost' IDENTIFIED BY 'MAKEUP-YOUR-OWN-PASSWORD'; 
#GRANT ALL PRIVILEGES ON nextcloud.* TO datamanager@'localhost' iDENTIFIED BY password; 
#FLUSH PRIVILEGES; 
 

# crontab -u www -e
# apppend
# */15 * * * * /usr/local/bin/php -f /usr/local/www/nextcloud/cron.php


/usr/local/bin/perl5.26.3: No such file or directory
*** Error code 127
