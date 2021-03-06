#!/bin/sh

# @author: Laurent FRANCOIS
# @date: 2018-12-06
#
# Bash script to install Nextcloud in FreeBSD (FreeNAS)
#
# git must have been installed. 

echo "Install nextcloud"
echo "Let's go..."
cd /root/install.nextcloud
pkg update
## install package for easy use of jail
pkg install  emacs tree wget zsh powerline-fonts pgpgpg tree sudo xtail git
# config git
# we can't clone git rep because we have to add an ssh in github.com
git config --global user.email "francois.oph@gmail.com"

## change to zsh
echo -e "\n--- change shell to zsh ---"
echo -e "\nzsh_version : $(zsh --version)"
chsh -s zsh
grep zsh /etc/shells
echo -e "\n--- get the oh-my-zsh rep ---"

## install oh-my-zsh 
wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | zsh
## problem here the above command stop the scritpt.

echo -e "\n--- Set the theme ---"
sed -i .bck-$(date +%d%m%Y) 's|^\(ZSH_THEME *=\).*|\1"aussiegeek"|g' /root/.zshrc
## add some aliases
echo 'alias zshconfig="emacs ~/.zshrc"' >> /root/.zshrc
echo 'alias cdetc="cd /usr/local/etc"' >> /root/.zshrc
echo 'alias tree="tree -C"' >> /root/.zshrc
echo 'alias tree1="tree -C -L1"'
echo 'alias tree2="tree -C -L2"'
echo 'eval $(ssh-agent)' >> /root/.zshrc

## INSTALL POSTGRESQL and NGINX
## at the time of this writing, the PHP PDO module for Postgres requires version 9.5
echo -e "\n ---- Install nginx et postgresql  ----"
pkg install nginx
pkg install postgresql95-server





## initialise the database server
echo -e "\n ---- Initialise the database server  ----"
CLUSTER_DB_PATH=" /usr/local/pgsql/data"
sudo -u pgsql initdb -D /usr/local/pgsql/data

## Turn on the services and network time synchronisation
echo -e "\n ---- Turn on the services and network time synchronisation ----"
sysrc ntpdate_enable=YES
sysrc nginx_enable=YES
sysrc postgresql_enable=YES
sysrc php_fpm_enable=YES
sysrc ntpdate_hosts=0.oceania.pool.ntp.org

## Turn on postgresql server
echo -e "\n ----  Turn on postgresql server ----"
service postgresql start

## Create a user 'nextcloud' in postgresql
## -e --echo Echo the commands that createdb generates and sends to the server.
USERDB=datamanager
DBNAME=nextcloud

createuser -U pgsql $USERDB

## Create a database named nextcloud
createdb --username pgsql $DBNAME --owner $USERDB -e

##Installing PHP
echo -e "\n ----  install PHP and modules PHP ----"
pkg install php72 php72-ftp php72-ctype php72-dom php72-gd php72-iconv php72-json php72-xml php72-mbstring php72-posix php72-simplexml php72-xmlreader php72-xmlwriter php72-zip php72-zlib php72-session php72-hash php72-filter php72-opcache php72-pdo_pgsql php72-curl php72-openssl php72-fileinfo php72-pgsql



##Coonfiguring PHP : /usr/local/etc/php-fpm.d/www.conf
##clear_env = no
#listen.owner = www
#listen.group = www
echo -e "\n ----  configure  PHP  ----"

WWW=/usr/local/etc/php-fpm.d/www.conf

if grep clear_env  $WWW;
then
    sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(clear_info *=).*|\2 no|g' $WWW
else
    echo 'clear_env = no' >> $WWW
fi
if grep listen.owner  $WWW;
then
    sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(listen.owner *=).*|\2 www|g' $WWW
else
    echo 'listen.owner = www' >> $WWW
fi
if grep listen.group  $WWW;
then
    sed -r -i .bck-$(date +%d%m%Y) 's|^([#;]? *)(listen.group *=).*|\2www|g' $WWW
else
    echo 'listen.owner = www' >> $WWW
fi


echo '\n ---  bye  -----'
echo -e "\n --- CE N'EST PAS FINI --- "
exit 1

##configuring the php.ini
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
echo '\n ---  bye  -----'
echo -e "\n --- CE N'EST PAS FINI --- "
exit 1
# opcache.enable=1
# opcache.enable_cli=0
# opcache.memory_consumption=128
# opcache.interned_strings_buffer=8
# opcache.max_accelerated_files=10000
# opcache.revalidate_freq=2
# opcache.save_comments=1
# upload_max_filesize = 1G

## start  php
service php-fpm start

## start nginx
service nginx start

### configuring caching
pkg install redis autoconf
sysrc redis_enable=YES
