#!/bin/sh

echo "Install nextcloud"
echo "Let's go..."

pkg update

## install package for easy use of jail
pkg install  emacs tree wget zsh powerline-fonts pgpgpg tree

## change to zsh
echo -e "\n--- change shell to zsh ---"
echo -e "\nzsh_version : $(zsh --version)"
chsh -s zsh
grep zsh /etc/shells
echo -e "\n--- get the oh-my-zsh rep ---"
#sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
echo -e "\n--- set the theme ---"
sed -i .bck-$(date +%d%m%Y) 's|^\(ZSH_THEME *=\).*|\1"aussiegeek"|g' /root/.zshrc
## add some aliases
echo 'alias zshconfig="emacs ~/.zshrc"' >> /root/.zshrc
echo 'alias cdetc=cd /usr/local/etc'

 
## INSTALL POSTGRESQL and NGINX
## at the time of this writing, the PHP PDO module for Postgres requires version 9.5
echo -e "\n ---- Install nginx et postgresql  ----"
pkg install nginx
pkg install postgresql95-server

## initialise the database server
echo -e "\n ---- Initialise the database server  ----"
su pgsql
initdb -D /usr/local/pgsql/data

## Turn on the services and network time synchronisation
echo -e "\n ---- Turn on the services and network time synchronisation ----"
sysrc {ntpdate,nginx,postgresql,php_fpm}_enable=YES
sysrc ntpdate_hosts=0.oceania.pool.ntp.org

## Turn on postgresql server
echo -e "\n ----  Turn on postgresql server ----"
service postgresql start

## Create a user 'nextcloud' in postgresql
## -e --echo Echo the commands that createdb generates and sends to the server.

USERDB=datamanager
createuser -U pgsql $USERDB
## Create a database named nextcloud
createdb --username pgsql nextcloud --owner $USERDB -e

##Installing PHP
echo -e "\n ----  install PHP and modules PHP ----"
pkg install php72 php72-{ftp,ctype,dom,gd,iconv,json,xml,mbstring,posix,simplexml,xmlreader,xmlwriter,zip,zlib,session,hash,filter,opcache,pdo_pgsql,curl,openssl,fileinfo}

echo '\n ---  bye  -----'
exit 1

##Coonfiguring PHP
echo -e "\n ----  configure  PHP  ----"
##clear_env = no
#listen.owner = www
#listen.group = www

##configuring the php.ini
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

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
