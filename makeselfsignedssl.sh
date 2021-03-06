#!/bin/sh

# @author Adriano Rosa (http://adrianorosa.com)
# @date: 2014-05-13 09:43
#
# Bash Script to create a new self-signed SSL Certificate
# At the end of creating a new Certificate this script will output a few lines
# to be copied and placed into NGINX site conf
#
# USAGE: this command will ask for the certificate name and number in days it will expire
# $ makeselfsignedssl.sh
#
# OPTIONAL: run the command straightforward
# $ mkselfssl mycertname 365

# TMP DIR
DIR_TMP = /root/tmp

if [ ! -d $DIR_TMP ]; then
    sudo mkdir -p $DIR_TMP
fi    
cd $DIR_TMP

# Default dir to place the Certificate
DIR_ETC="/usr/local/etc/"
DIR_SSL_CERT="$DIR_ETC/nginx/ssl/cert"
DIR_SSL_KEY="$DIR_ETC/nginx/ssl/private"

SSLNAME=$1
SSLDAYS=$2

if [ -z $1 ]; then
  printf "Enter the SSL Certificate Name:"
  read SSLNAME
fi

if [ -z $2 ]; then
  printf "How many days the Certificate will be valid:"
  read SSLDAYS
fi

if [ $SSLDAYS == "" ]; then
  $SSLDAYS = 365
fi

echo "Creating a new Certificate ..."
#openssl req -x509 -nodes -newkey rsa:2048 -keyout $SSLNAME.key -out $SSLNAME.crt -days $SSLDAYS
openssl req -subj '/CN=cabinet goeen/O=Laurent FRANCOIS/C=NC' -new -newkey rsa:2048 -sha256 -days $SSLDAYS  -nodes -x509 -keyout $SSLNAME.key -out  $SSLNAME.crt



# Make directory to place SSL Certificate if it doesn't exists
if [ ! -d $DIR_SSL_KEY ]; then
  sudo mkdir -p $DIR_SSL_KEY
fi

if [ ! -d $DIR_SSL_CERT ]; then
  sudo mkdir -p $DIR_SSL_CERT
fi

# Place SSL Certificate within defined path
sudo cp $SSLNAME.key $DIR_SSL_KEY/$SSLNAME.key
sudo cp $SSLNAME.crt $DIR_SSL_CERT/$SSLNAME.crt

# Remove SSL Certificate from tmp dir
rm $DIR_TMP/$SSLNAME.key
rm $DIR_TMP/$SSLNAME.crt

# Print output for Nginx site config
printf "+-------------------------------
+ SSL Certificate has been created.
+ Here is the NGINX Config for $SSLNAME
+ Copy it into your nginx config file
+-------------------------------\n\n
ssl_certificate      $DIR_SSL_CERT/$SSLNAME.crt;
ssl_certificate_key  $DIR_SSL_KEY/$SSLNAME.key;
ssl_session_cache shared:SSL:1m;
ssl_session_timeout  5m;\n\n"
