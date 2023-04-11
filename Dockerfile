FROM rockylinux:8

ENV container docker

ENV GLPI_VERSION 10.0.7

ENV GLPI_LANG en_US

ENV MARIADB_HOST mariadb-glpi

ENV MARIADB_PORT 3306

ENV MARIADB_DATABASE glpi

ENV MARIADB_USER glpi

ENV MARIADB_PASSWORD glpi

LABEL maintainer="info@itconsulting-hahn.de" \
      version="${GLPI_VERSION}" \
      description="GLPI docker image"

WORKDIR /var/www/html

# Update
RUN dnf -y update \
 && dnf -y upgrade

RUN dnf -y install epel-release yum-utils \
 && dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm \
 && dnf -y module enable php:remi-8.1 \
 && dnf -y update

# Install Apache, PHP und cronie
RUN dnf -y install php php-{mbstring,mysqli,xml,cli,ldap,openssl,xmlrpc,pecl-apcu,pecl-memcached,zip,curl,gd,json,session,imap,fpm,intl} \
 bzip2 httpd httpd-tools net-tools cronie crontabs mariadb findutils \
 && dnf -y clean all \
 && rm -rf /var/cache/yum

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in ; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done);

RUN rm -rf /lib/systemd/system/multi-user.target.wants/ \
 && rm -rf /etc/systemd/system/.wants/ \
 && rm -rf /lib/systemd/system/local-fs.target.wants/ \
 && rm -rf /lib/systemd/system/sockets.target.wants/udev \
 && rm -rf /lib/systemd/system/sockets.target.wants/initctl \
 && rm -rf /lib/systemd/system/basic.target.wants/ \
 && rm -rf /lib/systemd/system/anaconda.target.wants/*

# Update Apache Configuration
RUN sed -E -i -e '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf \
 && sed -E -i -e 's/DirectoryIndex (.*)$/DirectoryIndex index.php \1/g' /etc/httpd/conf/httpd.conf

# Update php-fpm Configuration
ADD apache/conf.d /etc/httpd/conf.d
ADD apache/php.d /etc/php.d

# add crontab and backup 
ADD crond/crontab /etc/crontab
ADD crond/crontab /var/spool/cron/root
ADD crond/crond-entrypoint.sh crond/backup.sh /
RUN chmod 0644 /etc/crontab \
 && chmod 0644 /var/spool/cron/root \
 && chmod 755 /crond-entrypoint.sh /backup.sh

# change config php-fpm
RUN sed -E -i -e 's/;listen.owner = nobody/listen.owner = apache/g' /etc/php-fpm.d/www.conf \
 && sed -E -i -e 's/;listen.group = nobody/listen.group = apache/g' /etc/php-fpm.d/www.conf \
 && sed -E -i -e 's/listen.acl_users = (.*)$/;listen.acl_users = \1/g' /etc/php-fpm.d/www.conf \
 && sed -E -i -e 's/session.cookie_httponly =/session.cookie_httponly = On/' /etc/php.ini \
 && sed -E -i -e "s+;date.timezone =+date.timezone = ${TZ}+" /etc/php.ini

# Install GLPI
ADD https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz /tmp/

RUN tar -zxf /tmp/glpi-${GLPI_VERSION}.tgz -C /tmp/ \
 && mv /tmp/glpi /var/www/glpi \
 && chown -R apache:apache /var/www/glpi/ \
 && rm -rf /tmp/glpi-${GLPI_VERSION}.tgz

VOLUME [ "/var/www/glpi/files", "/var/www/glpi/plugins", "/sys/fs/cgroup" ]

COPY apache/scripts/change_upload_max_filesize.php apache/scripts/default_upload_max_filesize.php apache/scripts/glpi-entrypoint.sh /opt/ 
COPY apache/scripts/glpi-config.service /usr/lib/systemd/system/

RUN chmod 755 /opt/glpi-entrypoint.sh \
 && systemctl enable httpd.service \
 && systemctl enable glpi-config.service \
 && systemctl enable crond.service
 #&& sed -E -i -e '/RuntimeDirectoryMode/a\ExecStartPost=/bin/bash -c "/opt/glpi-entrypoint.sh"' /usr/lib/systemd/system/php-fpm.service \
 #&& sed -E -i -e '/ExecStartPost=/a\PassEnvironment=POST_MAX_FILESIZE UPLOAD_MAX_FILESIZE MARIADB_HOST MARIADB_PORT MARIADB_USER MARIADB_PASSWORD MARIADB_DATABASE' /usr/lib/systemd/system/php-fpm.service \
 #&& sed -E -i -e '/ExecReload=/a\ExecStartPost=/bin/bash -c "/opt/glpi-entrypoint.sh"' /usr/lib/systemd/system/httpd.service \
 #&& sed -E -i -e '/ExecStartPost=/a\PassEnvironment=POST_MAX_FILESIZE UPLOAD_MAX_FILESIZE MARIADB_HOST MARIADB_PORT MARIADB_USER MARIADB_PASSWORD MARIADB_DATABASE' /usr/lib/systemd/system/httpd.service \
 #&& echo -n "/opt/glpi-entrypoint.sh" | tee -a /etc/rc.d/rc.local \
 #&& chmod +x /etc/rc.d/rc.local
 #&& echo "@reboot sleep 20 && /opt/glpi-entrypoint.sh" | tee -a /var/spool/cron/root
 #&& /opt/glpi-entrypoint.sh

WORKDIR /var/www/glpi

EXPOSE 80/tcp 

# Running systemd inside a docker container
CMD ["/usr/sbin/init"]

# Running systemd inside a docker container
#ENTRYPOINT ["/usr/sbin/init"]
