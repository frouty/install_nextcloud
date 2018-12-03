# avoir une plus jolie console.
## install zsh and others
`pkg install zsh git wget powerline-font`  
`zsh --version`  
## set zsh as your default shell
`chsh -s zsh`
## check /etc/shells
`grep zsh /etc/shells`
## check your shell
logout and login
`echo $SHELL` 
## install oh-my-zsh 
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

Add the following line to the "Files" section of xorg.conf or XF86Config:
- FontPath "/usr/local/share/fonts/powerline-fonts/" Not done

## set the theme
`sed -i .bck-$(date +%d%m%Y) 's|^\(ZSH_THEME *=\).*|\1"Mon Nouveau theme"|g' /path/to/.zshrc`  
logout > login.  

# pour avoir git 
- `pkg install git`
## add new ssh key in git repository
### add eval $(ssh-agent) in ~/.zshrc 
- ssh-add <path to private key>

## set ssh for jail.
service ssh on dans le WEBGUI
ssh lfs@10.66.0.240
iocage console nomdejail


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
