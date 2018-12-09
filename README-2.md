## créer la jail
- `iocage fetch` # pour avoir la liste des releases
- `iocage create -r 11.2-RELEASE -n unnomdejail  ip4_addr="igb0|10.66.0.241/24"`
ou en webGUI
### création de la jail en webGUI
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

## Creation des datasets

FreeNAS WebUI  
Create 2 datasets one for nextcloud files and one for database
Storage > Create ZFS Dataset

    Dataset Name = nextcloud-files
    Compression level = lz4
    Enable atime = Off

    Dataset Name = nextcloud-db
    Compression level = zle
    Enable atime = Off
    Record Size = 16K
	
## création d'un nouvel user pour la database	
Accounts > Users > Add new user 
	Full Name : SQL user
	Username : pgsql
	Password
	No login

## changement des permissions
Storage > Pools > 	
	- nextcloud-db permission > 
	- ACL type : Unix
	- Apply User
	- User : pgsql
	- Apply group 
	- Group : wheel
	- Apply permissions recursively : Yes


## add storages in the jail
Jails > Mount points > 
	- Sources : dataset on est outside de la jail. 
	- destination : on se trouve dans la jail : /mnt/iocage/jails/MyNextcloud/mnt/files
	
	au final :
	- source : /mnt/mlp-pool/nextcloud-files 
	- Destination : /mnt/mlp-pool/iocage/jails/MyNextcloud/root/mnt/files 
	
	et 
	- source : /mnt/mlp-pool/nextcloud-db
	- Destination : /mnt/mlp-pool/iocage/jails/MyNextcloud/root/user/local/pgsql/data
	
### Setting primary cache In FreeNAS UserSpace Shell:
	WebGUI > shell > $ zfs set primarycache=metadata mlp-pool/jail/nextcloud/data/nextcloud-db


# se connecter à la nouvelle jail
- `iocage start unnomdejail`
- `iocage console unnomdejail`

# installer git pour pouvoir récuper les scripts de configuration
cd /root/
pkg install git
## add new ssh key in git repository
ssh-keygen -t rsa -b 4096 -C "francois.oph@gmail.com"
### utiliser vi pour faire un copier/coller de la clef. on peut laisser les retours à la ligne.
### add eval $(ssh-agent) in ~/.zshrc
echo 'eval $(ssh-agent)' >> /root/.zshrc
### ssh-add <path to private key>
### clone the repository
cd /root/
git clone git@github.com:frouty/install_nextcloud.git
### chmod +x /root/install.nextcloud/install.nextcloud1.sh

# démarrer le scipt install_nextcloud1.sh 
qui va installer un certains nombre de paquets pour avoir une console plus jolie et plus fonctionnelle. 
Qui va installer postgresql php 
# avoir une plus jolie console.
## install zsh and others
`[jail]pkg install tree zsh git wget powerline-fonts sudo xtrail`  
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
## set the theme
`[jail]sed -i .bck-$(date +%d%m%Y) 's|^\(ZSH_THEME *=\).*|\1"Mon Nouveau theme"|g' /path/to/.zshrc`  
logout > login.  



## set ssh for jail.
- `service ssh on dans le WEBGUI`
- `ssh lfs@10.66.0.240`
- `iocage console nomdejail`


# INSTALLATION DE NEXTCLOUD
https://medium.com/@vermaden/nextcloud-13-on-freebsd-95cef1fad291



# autre tuto sur l'install de nexcloud freebsd11 et nginx et postgresql
http://unflyingobject.com/posts/nextcloud-12-from-scratch-with-freebsd-11/
mais quand assez incomplét notamment pour la configuration de nginx. 
```
pkg update
## install package for easy use of jail
pkg install git emacs tree wget zsh powerline-fonts pgpgpg tree
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
sudo -u pgsql initd -D /usr/local/pgsql/data

Success. You can now start the database server using:

    pg_ctl -D /usr/local/pgsql/data -l logfile start
```

initdb crée un nouvel database cluster. C'est une collection de databases qui est managé pour une instance du server

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
- 'nextcloud' the user you create

### create a database
`createdb -U pgsql nextcloud -O nextcloud -e`  
- O : owner
- e : echo the commands that createdb generate and send to the server

### Installing PHP

`pkg install php71 php71-{ftp,ctype,dom,gd,iconv,json,xml,mbstring,posix,simplexml,xmlreader,xmlwriter,zip,zlib,session,hash,filter,opcache,pdo_pgsql,pgsql,curl,openssl,fileinfo}`

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
curl -O https://pecl.php.net/get/redis-3.1.4.tgz (4.2.0.tgz)
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
fetch https://nextcloud.com/nextcloud.asc
gpg --import nextcloud.asc                                                           
gpg --verify nextcloud-$NCRELEASE.tar.bz2.asc nextcloud-$NCRELEASE.tar.bz2
```

### where to put the nextcloud installation
j'ai fait un dataset nextcloud-data
je l'ai monté sur /mnt/mlp-poll/jails/testjail2/root/mnt mais je ne le vois pas.
on va  essayer autre chose.
j'ai monté /mnt/mlp-pool/nextcloud-data sur /mnt/mlp-pool/iocage/jails/testjail2/root/mynextcloud  
et dans la jail j'ai mynextcloud qui se trouve sous / (la racine) 

tar -zxvf latest-14.tar.bz2
mv /root/tmp/nextcloud/ /usr/local/www
chown -R www:www /usr/local/www
sudo -u www env VISUAL=emacs crontab -e
*/15 * * * * /usr/local/bin/php -f /usr/local/www/nextcloud/cron.php

### configuring nginx
```
cd /usr/local/etc/nginx
 curl -o /usr/local/etc/nginx/nextcloud.conf https://gist.githubusercontent.com/filipp/6547dfe9524a1a05e49f69397ae9adff/raw/298b98e6f49f938fd8664f550b72ac1b3c671a55/nextcloud.conf
echo "include nextcloud.conf;" >> /usr/local/etc/nginx/nginx.conf
```
Il faut mettre 'include nextcloud.conf;' dans un block http.

`# ps axwww -o %cpu,rss,time,command -J IDdelajail` je vois que tous les services on l'air de tourner


J'ai modifié le nextcloud.conf. et maintenant ca marche. 

Au moment de la configuration on peut définir le chemin de data folder

J'ai toujours le probleme de la configuration du pb_hba.conf 

pour le trouver find / -name pg_hba.conf
je rajoute la ligne. et puis j'arrive à me passer l'étape finale de configuration.

`host    all             all             0.0.0.0/0               trust`

et ensuite j'ai pu la changer en 
`host    nextcloud       datamanager     10.66.0.243/24          trust` et cela continu à fonctionner

Par contre avant la fin de la phase finale de configuration et bien cela ne marche pas.



# pour en savoir un peu plus sur les fichiers de configuration de nginx
https://www.linode.com/docs/web-servers/nginx/how-to-configure-nginx/
https://gist.github.com/jessedearing/2351836

# self signed certificate

run le script makeselfsignedssl.sh 

sinon en ressources:
```
pkg install openssl
cd /root/tmp
openssl genrsa -des3 -out myssl.key 1024
openssl req -new -key myssl.key -out myssl.csr
cp myssl.key myssl.key.org
openssl rsa -in myssl.key.org -out myssl.key
rm myssl.key.org
openssl x509 -req -days 365 -in myssl.csr -signkey myssl.key -out myssl.crt
mkdir -p /usr/local/etc/ssl/{certs,private}
cp /root/tmp/myssl.crt /usr/local/etc/ssl/certs/
cp /root/tmp/myssl.key /usr/local/etc/ssl/private

```
```
#!/bin/bash
echo "Generating an SSL private key to sign your certificate..."
openssl genrsa -des3 -out myssl.key 1024

echo "Generating a Certificate Signing Request..."
openssl req -new -key myssl.key -out myssl.csr

echo "Removing passphrase from key (for nginx)..."
cp myssl.key myssl.key.org
openssl rsa -in myssl.key.org -out myssl.key
rm myssl.key.org

echo "Generating certificate..."
openssl x509 -req -days 365 -in myssl.csr -signkey myssl.key -out myssl.crt

echo "Copying certificate (myssl.crt) to /etc/ssl/certs/"
mkdir -p  /etc/ssl/certs
cp myssl.crt /etc/ssl/certs/

echo "Copying key (myssl.key) to /etc/ssl/private/"
mkdir -p  /etc/ssl/private
cp myssl.key /etc/ssl/private/
```

# regle nat sur le routeur
network > firewall > Port forwards 
source zone : wan
source ip address : any
source port : any
external IP : any
external port 444 (odoo is on 443)
internal zone : lan
internal ip address : 10.66.0.243 <--- IP de la jail 
internal port any

Ca marche mais le site repond access through untrusted domain.
/usr/local/www/nextcloud/config/config.sample.php
usr/local/www/nextcloud/config/config.php
https://help.nextcloud.com/t/adding-a-new-trusted-domain/26

# config nextcloud/config.php
$CONFIG = array (
  'instanceid' => 'oc6yzvt1yaal',
  'passwordsalt' => '0hDr5CXAO9qRxjlh6akWcDR6Grk0Ne',
  'secret' => 'UcEIIFyYaNpYyruq87c51F8CrbfXjuQrgVSxZlmrltjlZ6Kk',
  'trusted_domains' =>
  array (
    0 => '10.66.0.243',
    1 => 'goeen.ddns.net'
  ),
  'datadirectory' => '/usr/local/www/nextcloud/data',
  'dbtype' => 'pgsql',
  'version' => '14.0.4.2',
  'overwrite.cli.url' => 'http://10.66.0.243',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost:5432',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'datamanager',
  'dbpassword' => '',
  'installed' => true,
);

`service nginx restart`

#### FIN ####




# let's encrypt
je n'ai pas utilisé car il semble qu'il faille un nom de domain.

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
permet de selectionner un plugin et des opytions pour obtenir le certificat.
Recommande de choisir le `webroot plugin`
apres je n'ai pas compris

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
# nextcloud et postgresql 
installed and enable postgresql extension for php.

# des explications sur installation nginx et freebsd
https://www.cyberciti.biz/faq/freebsd-install-nginx-webserver/
qui m'ont bien aidé.   
J'ai fait des modifications dans nginx/nextcloud.conf   
et je peux avoir la page web de fin de configuration de nextcloud.  
mais j'ai un probleme avec postgresql  
rror while trying to create admin user:  
Failed to connect to the database: An exception occured in driver: SQLSTATE[08006] [7]  
FATAL: no pg_hba.conf entry for host "10.66.0.241", user "nextcloud", database "nextcloud", SSL off 

Allons voir pg_hba.conf  
Dans ce fichier on va definir quel client peut s'autentifier sur le serveur. : host (?) , database sur laquelle il a le droit de se connecter, la méthode d'authentification, etc...
quand un client demande une connection la demande spécifie une database, un postgresql username, 


# local       DATABASE  USER  METHOD  [OPTIONS]
# host        DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
# host[no]ssl DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
- host pour un host remote qui pourra se connecter au server postgresql 
- local pour les 

### fichier de conf de postgresql : ' /usr/local/pgsql/data/postgresql.conf'
