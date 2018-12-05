# créer la jail
- `iocage fetch` # pour avoir la liste des releases
- `iocage create -r 11.2-RELEASE -n unnomdejail  ip4_addr="igb0|10.66.0.241/24"`
# se connecter à la nouvelle jail
- `iocage start unnomdejail`
- `iocage console unnomdejail`
# avoir une plus jolie console.
## install zsh and others
`[jail]pkg install zsh git wget powerline-font`  
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


je ne trouve pas le fichier /usr/local/etc/my.cnf fichier de configuration de mysql. 

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
