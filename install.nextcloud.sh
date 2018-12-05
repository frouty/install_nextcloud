#!/bin/sh

echo "hello"


# pkg update
## install package for easy use of jail
# pkg install git emacs tree wget zsh poxerline-fonts
## install package for nextcloud
# pkg install nginx mariadb101-server redis php71-bz2 php71-ctype php71-curl php71-dom php71-exif php71-fileinfo php71-filter php71-gd php71-hash 
# php71-iconv php71-intl php71-json php71-mbstring php71-mcrypt php71-pdo_mysql php71-openssl php71-posix php71-session php71-simplexml php71-xml 
# php71-xmlreader php71-xmlwriter php71-xsl php71-wddx php71-zip php71-zlib php71-opcache


#portsnap fetch extract
#make config-recursive install -C /usr/ports/databases/pecl-redis
#make config-recursive install -C /usr/ports/devel/pecl-APCu
#sysrc 'nginx_enable=YES' 
#sysrc 'php_fpm_enable=YES' 
#sysrc 'mysql_enable=YES' 
#sysrc 'redis_enable=YES'
#cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini


# echo "create the /usr/local/etc/nginx/nginx.conf file"
# cat <<EOF > /root/install_nextcloud/nginx.conf
# worker_processes 2;

# events {
#     worker_connections  1024;
# }

# http {
#     include      mime.types;
#     default_type  application/octet-stream;
#     sendfile        off;
#     keepalive_timeout  65;
#     gzip off;

#     server {
#         root /usr/local/www;
#         location = /robots.txt { allow all; access_log off; log_not_found off; }
#         location = /favicon.ico { access_log off; log_not_found off; }
#         location ^~ /owncloud {s
#             error_page 403 /owncloud/core/templates/403.php;
#             error_page 404 /owncloud/core/templates/404.php;
#             location /owncloud {
#                 rewrite ^ /owncloud/index.php$request_uri;
#             }
#             location ~ ^/owncloud/(?:build|tests|config|lib|3rdparty|templates|data)/ {
#                 deny all;
#             }
#             location ~ ^/owncloud/(?:\.|autotest|occ|issue|indie|db_|console) {
#                 deny all;
#             }
#             location ~ ^/owncloud/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
#                 fastcgi_split_path_info ^(.+\.php)(/.*)$;
#                 include fastcgi_params;
#                 fastcgi_pass unix:/var/run/php-fpm.sock;
#                 fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#                 fastcgi_param PATH_INFO $fastcgi_path_info;
#                 fastcgi_param front_controller_active true;
#                 fastcgi_intercept_errors on;
#             }
#             location ~* \.(?:css|js|woff|svg|gif)$ {
#                 try_files $uri /owncloud/index.php$request_uri;
#                 add_header Cache-Control max-age=15778463;
#             }
#             location ~* \.(?:png|html|ttf|ico|jpg|jpeg)$ {
#                 try_files $uri /owncloud/index.php$request_uri;
#             }

#         }
#     }
# }
# EOF


# replace the relevant lines in /usr/local/etc/php.ini
#cgi.fix_pathinfo=0				\
#date.timezone = America/Los_Angeles		\
#apc.enable_cli=1
#PHPINI="/usr/local/etc/php.ini"
#echo "set variable path to php.ini : ${PHPINI}"
#sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(cgi.fix_pathinfo *=).*|\2"0"|g' $PHPINI
#sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(date.timezone *=).*|\2"Pacific/Noumea"|g' $PHPINI

if  grep apc.enable_cli /usr/local/etc/php.ini;
then echo "hello I found apc.enable_cli"
else echo "Ooops I don't find it"
     
## replace the relevant lines in /usr/local/etc/php-fmp.d/wwww.conf
#listen = /var/run/php-fpm.sock
#listen.owner = www
#listen.group = www
#env[PATH] = /usr/local/bin:/usr/bin:/bin 
# toutes ces lignes existent et seule la premiere est  a modifier

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


## Replace /add the relevant lines in /usr/loca/etc/redis.conf
#port 0
#unixsocket /tmp/redis.sock
#unixsocketperm 777
# le fichier existe.




# installation de nextcloud
NCRELEASE=14.0.4
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
tar -jxf nextcloud-$NCRELEASE.tar.bz2 -C /usr/local/www
# rm nextcloud-$NCRELEASE.tar.bz2
#chown -R www:www /usr/local/www/owncloud /mnt/files
