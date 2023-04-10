#!/bin/bash

ConfigDataBase () {

      {
        echo "<?php"; \
        echo "class DB extends DBmysql {"; \
        echo "   public \$dbhost     = \"${MARIADB_HOST}\";"; \
        echo "   public \$dbport     = \"${MARIADB_PORT}\";"; \
        echo "   public \$dbuser     = \"${MARIADB_USER}\";"; \
        echo "   public \$dbpassword = \"${MARIADB_PASSWORD}\";"; \
        echo "   public \$dbdefault  = \"${MARIADB_DATABASE}\";"; \
        echo "}"; \
        echo ; 
      } > /var/www/glpi/config/config_db.php

}


VerifyDir () {

  DIR="/var/www/glpi/files/_cron
  /var/www/glpi/files/_dumps
  /var/www/glpi/files/_graphs
  /var/www/glpi/files/_log
  /var/www/glpi/files/_lock
  /var/www/glpi/files/_pictures
  /var/www/glpi/files/_plugins
  /var/www/glpi/files/_rss
  /var/www/glpi/files/_tmp
  /var/www/glpi/files/_uploads
  /var/www/glpi/files/_cache
  /var/www/glpi/files/_sessions
  /var/www/glpi/files/_locales
  /var/www/glpi/files/_inventories"

  for i in $DIR
  do 
    if [ ! -d $i ]
    then
      echo -n "Creating $i dir... " 
      mkdir -p $i
      echo "[done]"
    fi
  done
}

VerifyKey () {

  if [ ! -e /var/www/glpi/config/glpicrypt.key ]
  then
    php -c /etc/php.ini /var/www/glpi/bin/console glpi:security:change_key --no-interaction
  fi

}

SetPermissions () {
  echo -n "Setting chown in files and plugins... "
  chown -R apache:apache /var/www/glpi/files
  chown -R apache:apache /var/www/glpi/plugins
  echo "[done]"

}

echo "+----------------------------------------------------------+"
echo "|                                                          |"
echo "|      Welcome to GLPI IT Asset Management Docker!      |"
echo "|                                                          |"
echo "+----------------------------------------------------------+"

echo -n "Configure MySQL Database... "
ConfigDataBase
echo [ done ]

VerifyDir

# Delete installation file "install.php" if glpi is already installed
if [[ -e "/var/www/glpi/config/glpicrypt.key" ]]
then
   echo "GLPI has already been installed."
   echo "GLPI installation \"install.php\" file will be deleted."
   echo -n "Deleting \"install.php\" file... " 
   rm -rf /var/www/glpi/install/install.php
   echo "[done]"
else
   echo "GLPI is not installed yet."
fi

VerifyKey

echo -n "Set permissins... "
SetPermissions
echo [ done ]

# Set upload_max_filesize
if [[ -z "$UPLOAD_MAX_FILESIZE" ]]
then 
   echo "UPLOAD_MAX_FILESIZE is not defined."
   php /opt/default_upload_max_filesize.php
else
   echo -n "Setting UPLOAD_MAX_FILESIZE... "
   #sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = $UPLOAD_MAX_FILESIZE/" /etc/php.ini
   sed -i -e "/upload_max_filesize = 2M/c\upload_max_filesize = $UPLOAD_MAX_FILESIZE" /etc/php.ini
   echo "[done]"
   echo -n "Running php script \"change_upload_max_filesize.php\"... "
   php /opt/change_upload_max_filesize.php
   echo "[done]"
fi

# Set upload_max_filesize
if [[ -z "$POST_MAX_FILESIZE" ]]
then 
   echo "POST_MAX_FILESIZE is not defined."
else
   echo -n "Changing POST_MAX_FILESIZE... "
   #sed -i -e "s/post_max_size = 8M/post_max_size = $POST_MAX_FILESIZE/" /etc/php.ini
   sed -i -e "/post_max_size = 8M/c\post_max_size = $POST_MAX_FILESIZE" /etc/php.ini
   echo "[done]"
fi

echo "+----------------------------------------------------------+"
echo "|                 OK, prepare finshed ;-)                  |"
echo "|                                                          |"
echo "|      Starting GLPI IT Asset Management  Docker...      |"
echo "+----------------------------------------------------------+"
echo


# Security configuration for sessions cookies
#sed -i -e 's/session.cookie_httponly =/session.cookie_httponly = On/' /etc/php.ini

# set TIMEZONE
#if [[ -z "${TZ}" ]]; then 
#   echo "TIMEZONE is unset."
#else 
#   echo "Set TIMEZONE."
#   sed -i -e "s+;date.timezone =+date.timezone = ${TZ}+" /etc/php.ini 
#fi

### Setup crond
#echo "*/2 * * * * root /usr/bin/php -c /etc/php.ini /var/www/glpi/front/cron.php" > /etc/cron.d/glpi
#echo "*/5 * * * * root /usr/bin/php -c /etc/php.ini /var/www/glpi/front/cron.php --forcequeudnotification" >> /etc/cron.d/glpi
#echo "*/5 * * * * root /usr/bin/php -c /etc/php.ini /var/www/glpi/front/cron.php --forcemailgate" >> /etc/cron.d/glpi

#httpd -D FOREGROUND
