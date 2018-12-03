#!/bin/sh
pkg update
pkg install nginx mariadb101-server redis php71-bz2 php71-ctype php71-curl php71-dom php71-exif php71-fileinfo php71-filter php71-gd php71-hash 
php71-iconv php71-intl php71-json php71-mbstring php71-mcrypt php71-pdo_mysql php71-openssl php71-posix php71-session php71-simplexml php71-xml 
php71-xmlreader php71-xmlwriter php71-xsl php71-wddx php71-zip php71-zlib php71-opcache


echo "create the /usr/local/etc/nginx/nginx.conf file"
cat <<EOF > /home/root/install_nextcloud/nginx.conf
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
        location = /favicon.ico { access_log off; log_not_found off; }
        location ^~ /owncloud {
            error_page 403 /owncloud/core/templates/403.php;
            error_page 404 /owncloud/core/templates/404.php;
            location /owncloud {
                rewrite ^ /owncloud/index.php$request_uri;
            }
            location ~ ^/owncloud/(?:build|tests|config|lib|3rdparty|templates|data)/ {
                deny all;
            }
            location ~ ^/owncloud/(?:\.|autotest|occ|issue|indie|db_|console) {
                deny all;
            }
            location ~ ^/owncloud/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
                fastcgi_split_path_info ^(.+\.php)(/.*)$;
                include fastcgi_params;
                fastcgi_pass unix:/var/run/php-fpm.sock;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
                fastcgi_param front_controller_active true;
                fastcgi_intercept_errors on;
            }
            location ~* \.(?:css|js|woff|svg|gif)$ {
                try_files $uri /owncloud/index.php$request_uri;
                add_header Cache-Control max-age=15778463;
            }
            location ~* \.(?:png|html|ttf|ico|jpg|jpeg)$ {
                try_files $uri /owncloud/index.php$request_uri;
            }

        }
    }
}
EOF
