# créer la jail
- `iocage fetch` # pour avoir la liste des releases
- `iocage create -r 11.2-RELEASE -n unnomdejail  ip4_addr="igb0|10.66.0.241/24"`
# se connecter à la nouvelle jail
- `iocage start unnomdejail`
- `iocage console unnomdejail`
# avoir une plus jolie console.
## install zsh and others
`[jail]pkg install tree zsh git wget powerline-fonts`  
`[jail]zsh --version`  
## set zsh as your default shell
`[jail]chsh -s zsh`
## check /etc/shells
`[jail]grep zsh /etc/shells`
## check your shell
logout and login
`[jail]echo $SHELL` 
## install oh-my-zsh 
`[jail]sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"`

Add the following line to the "Files" section of xorg.conf or XF86Config:
- FontPath "/usr/local/share/fonts/powerline-fonts/" 
- Not done et cela marche.

## set the theme
`[jail]sed -i .bck-$(date +%d%m%Y) 's|^\(ZSH_THEME *=\).*|\1"Mon Nouveau theme"|g' /path/to/.zshrc`  
logout > login.  

## add new ssh key in git repository
### utiliser vi pour faire un copier/coller de la clef. on peut laisser les retours à la ligne.
### add eval $(ssh-agent) in ~/.zshrc 
- ssh-add <path to private key>

## set ssh for jail.
- `service ssh on dans le WEBGUI`
- `ssh lfs@10.66.0.240`
- `iocage console nomdejail`


# INSTALLATION DE NEXTCLOUD
https://medium.com/@vermaden/nextcloud-13-on-freebsd-95cef1fad291
## Creation des datasets

FreeNAS WebUI
Storage > Create ZFS Dataset

    Dataset Name = nextcloud-files
    Compression level = lz4
    Enable atime = Off

    Dataset Name = nextcloud-db
    Compression level = zle
    Enable atime = Off
    Record Size = 16K
	
Accounts > Users > Add new user 
	Full Name : SQL user
	Username : mysql
	Password
	No login

Storage > Pools > 	
	- nextcloud-db permission > 
	- ACL type : Unix
	- Apply User
	- User : mysql
	- Apply group 
	- Group : wheel
	- Apply permissions recursively : Yes

Jails > Add Jails
[root]iocage create -r 11.2-RELEASE -n unnomdejail
	- MyNextcloud
	- Release : 11.2 RELEASE-p4
	- vnet : YES
	- IPv4 interface : igb0
	- IPv4 address : 10.66.0.241
	- IPv4 mask : 24
	- IPv4 default Router : 10.66.0.1
	- Autostart Yes

Jails > Mount points > 
	- Sources : dataset on est outside de la jail. 
	- destination : on se trouve dans la jail : /mnt/iocage/jails/MyNextcloud/data
	
	au final :
	- source : /mnt/mlp-pool/nextcloud-files 
	- Destination : /mnt/mlp-pool/iocage/jails/MyNextcloud/root/mnt/files 
	
	et 
	- source : /mnt/mlp-pool/nextcloud-db
	- Destination : /mnt/mlp-pool/iocage/jails/MyNextcloud/root/var/db/mysql
	
	Setting primary cache In FreeNAS UserSpace Shell:
	WebGUI > shell > $ zfs set primarycache=metadata mlp-pool/jail/nextcloud/data/nextcloud-db


# je ne trouve pas le fichier /usr/local/etc/my.cnf fichier de configuration de mysql.
il faut regarder le script /usr/local/etc/rc.d/mysql-server on trouve :
```
: ${mysql_dbdir="/var/db/mysql"}
: ${mysql_optfile="${mysql_dbdir}/my.cnf"}

```
Ce qui veut dire que le fichier my.cnf est sous /var/db/mysql. Je ne le trouve pas. 

Il est écrit partout que mysql marche tres bien sans fichier de configuration

On peut trouver les fichiers qu'un port install dans sa pkg-plist in usr/ports/databases/mysql80-server/pkg-plist.

Mariadb est un fork de mysql. 
On ne peut pas installer mardiadb et mysql en meme temps.

## utiliser le script install_nexcloud.sh du rep install_nexcloud dans github

# administration de la database 

- on se connect : `mysql -u root -p` 
- passwd : habituel
- pour avoir la liste des databases : `show databases;`
- pour avoir la liste des tables:
  - on se connecte à la database : `use unnomdetable;`
  - `show tables;`

## comment connaitre la version 
- on se connect : `mysql -u root -p` 
- passwd : habituel
- `\s`


# autre tuto sur l'install de nexcloud freebsd11 et nginx et postgresql
http://unflyingobject.com/posts/nextcloud-12-from-scratch-with-freebsd-11/
```
pkg update

## install package for easy use of jail
pkg install git emacs tree wget zsh powerline-fonts pgpgpg tree
### install nginx and postgresql 
```
### install postgresql and nginx
```
## INSTALL POSTGRESQL and NGINX
## at the time of this writing, the PHP PDO module for Postgres requires version 9.5
pkg install nginx
pkg install postgresql95-server
```
# initialize database
```
## initialise the database server
su pgsql
initd -D /usr/local/pgsql/data

Success. You can now start the database server using:

    pg_ctl -D /usr/local/pgsql/data -l logfile start
```
# Start the postgresql server
```
# service postgresql start
LOG:  could not create IPv6 socket: Protocol not supported Est ce que c'est un probleme?
LOG:  ending log output to stderr
HINT:  Future log output will go to log destination "syslog".
```

### create a user
`createuser -U pgsql nextcloud`  
- U : user to connect as
### create a database
`createdb -U pgsql nextcloud -O nextcloud -e`  
- O : owner
- e : echo the commands that createdb generate and send to the server

### Installing PHP

`pkg install php71 php71-{ftp,ctype,dom,gd,iconv,json,xml,mbstring,posix,simplexml,xmlreader,xmlwriter,zip,zlib,session,hash,filter,opcache,pdo_pgsql,curl,openssl,fileinfo}`

mais je n'ai pas du tout autant de paquets installés que sur le tuto. 

pour avoir les dépendances:
https://docs.nextcloud.com/server/12/admin_manual/installation/source_installation.html

### Coonfiguring PHP
emacs /usr/local/etc/php-fpm.d/www.conf
- clear_env = no
- listen.owner = www
- listen.group = www

### configuring the php.ini
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

Uncomment:                                                    
- opcache.enable=1
- opcache.enable_cli=0
- opcache.memory_consumption=128
- opcache.interned_strings_buffer=8
- opcache.max_accelerated_files=10000
- opcache.revalidate_freq=2
- opcache.save_comments=1

Upload the limite:
- upload_max_filesize = 1G

### start the PHP and nginx service
```
service php-fpm start
Performing sanity check on php-fpm configuration:
[07-Dec-2018 04:15:07] NOTICE: configuration file /usr/local/etc/php-fpm.conf test is successful

Starting php_fpm.

```
### start nginx service
```
 service nginx start
Performing sanity check on nginx configuration:
nginx: the configuration file /usr/local/etc/nginx/nginx.conf syntax is ok
nginx: configuration file /usr/local/etc/nginx/nginx.conf test is successful
Starting nginx.
```

### configuring caching
install the redis server and corresponding php extension
```
pkg install redis autoconf
sysrc redis_enable=YES
service redis start
Starting redis.
```
pkg doesn't include php redis extension

```
mkdir /root/tmp
cd /root/tmp
curl -O https://pecl.php.net/get/redis-3.1.4.tgz
tar zxvf redis-3.1.4.tgz
cd redis-3.1.4
phpize
./configure && make && make test

```
```
make install
Installing shared extensions:     /usr/local/lib/php/20160303/

```
```
echo extension=redis.so >> /usr/local/etc/php/ext-20-redis.ini
```

```
service php-fpm restart
Performing sanity check on php-fpm configuration:
[07-Dec-2018 04:41:52] NOTICE: configuration file /usr/local/etc/php-fpm.conf test is successful

Stopping php_fpm.
Waiting for PIDS: 68668.
Performing sanity check on php-fpm configuration:
[07-Dec-2018 04:41:52] NOTICE: configuration file /usr/local/etc/php-fpm.conf test is successful

Starting php_fpm.
```

### installing nextcloud
```
cd /root/tmp
fetch https://download.nextcloud.com/server/releases/nextcloud-$NCRELEASE.tar.bz2
fetch https://download.nextcloud.com/server/releases/nextcloud-$NCRELEASE.tar.bz2.sha256
fetch https://download.nextcloud.com/server/releases/nextcloud-$NCRELEASE.tar.bz2.asc# 
cd path to where is download nextcloud
echo "Verify integrity"
shasum -a 256 -c nextcloud-14.0.4.tar.bz2.sha256 < nextcloud-14.0.4.tar.bz2

#verify authenticity
echo "Verify authenticity"
gpg --import nextcloud.asc                                                           
gpg --verify nextcloud-$NCRELEASE.tar.bz2.asc nextcloud-$NCRELEASE.tar.bz2
```

### where to put the nextcloud installation
j'ai fait un dataset nextcloud-data
je l'ai monté sur /mnt/mlp-poll/jails/testjail2/root/mnt mais je ne le vois pas.
on va  essayer autre chose.
j'ai monté /mnt/mlp-pool/nextcloud-data sur /mnt/mlp-pool/iocage/jails/testjail2/root/mynextcloud  
et dans la jail j'ai mynextcloud qui se trouve sous / (la racine) 

mv /root/tmp/nextcloud/* /mynextcloud
chown -R www /mynextcloud
sudo -u www env VISUAL=emacs crontab -e
*/15 * * * * /usr/local/bin/php -f /mynextcloud/cron.php

### configuring nginx
```
cd /usr/local/etc/nginx
 curl -o /usr/local/etc/nginx/nextcloud.conf https://gist.githubusercontent.com/filipp/6547dfe9524a1a05e49f69397ae9adff/raw/298b98e6f49f938fd8664f550b72ac1b3c671a55/nextcloud.conf
echo "include nextcloud.conf;" >> /usr/local/etc/nginx/nginx.conf
```
Il faut mettre 'include nextcloud.conf;' dans un block http.

file or directory:fopen('/etc/ssl/nginx/cloud.example.com.crt','r') error:2006D080:BIO routines:BIO_new_file:no such file)
nginx: configuration file /usr/local/etc/nginx/nginx.conf test failed


### adding ssl encryption
pkg install py27-certbot
```
# nano /usr/local/etc/nginx/nextcloud.conf
location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
  #deny all;
}
```
```
 tree /etc/ssl
/etc/ssl
|-- cert.pem -> /usr/local/share/certs/ca-root-nss.crt
`-- openssl.cnf
```
`certbot --staging certonly --webroot -w /zroot/nextcloud -d cloud.example.com`

```
tree /usr/local/etc/letsencrypt -L 2
.
|-- accounts
|   |-- acme-staging-v02.api.letsencrypt.org
|   `-- acme-v02.api.letsencrypt.org
|-- csr
|   |-- 0000_csr-certbot.pem
|   `-- 0001_csr-certbot.pem
|-- keys
|   |-- 0000_key-certbot.pem
|   `-- 0001_key-certbot.pem
|-- renewal
`-- renewal-hooks
    |-- deploy
    |-- post
    `-- pre
```
si à nouveau `certbot --staging certonly --webroot -w /zroot/nextcloud -d cloud.example.com`   
on va avoir un nouveau csr/000x_csr-certbot.pem et un nouveau keys/000x_key-certbot.pem 

j'ai comme erreur:  
[emerg] BIO_new_file("/etc/ssl/nginx/cloud.example.com.crt") failed (SSL: error:02001002:system library:fopen:No such file or directory:fopen('/etc/ssl/nginx/cloud.example.com.crt','r') error:2006D080:BIO routines:BIO_new_file:no such file)

```
/etc/ssl
|-- cert.pem -> /usr/local/share/certs/ca-root-nss.crt
`-- openssl.cnf
```
je veux d'abord essayé sans le https pour voir si cela marche

You can use Nextcloud over plain http, but we strongly encourage you to use SSL/TLS to encrypt all of your server traffic, and to protect user’s logins and data in transit.

    Remove the server block containing the redirect
    Change listen 443 ssl to listen 80;
    Remove ssl_certificate and ssl_certificate_key.
    Remove fastcgi_params HTTPS on;


nginx -t c'est bon 
http://10.66.0.241 me donne la page de nginx pas la page de nextcloud
Je fais un restart de php-fmp et maintenant http://10.66.0.241 est en erreur.

`# ps axwww -o %cpu,rss,time,command -J IDdelajail` je vois que tous les services on l'air de tourner







# pour en savoir un peu plus sur les fichiers de configuration de nginx
https://www.linode.com/docs/web-servers/nginx/how-to-configure-nginx/


# let's encrypt
pour permettre https il faut un certificat (un fichier particulier) fourni par a Certificat Authority (CA).  
let's encrypt est un CA.
- Acme protocol qui tourne sur le server
- ssh access sur le server
- Cerbot ACME client (c'est un client mais il y en a d'autres)
https://certbot.eff.org/docs/intro.html
## acme protocole
pas trouvé grand  chose
## cerbot ACME  client

https://certbot.eff.org/lets-encrypt/freebsd-nginx

## installation de cerbot ACME client
### avec le port 
cd /usr/ports/security/py-certbot && make install clean
### avec le package
pkg install py27-certbot
## get started
`sudo cerbot certonly`
permet de selectionner un plugin et des options pour obtenir le certificat.
Recommande de choisir le `webroot plugin`
apres je n'ai pas compris
