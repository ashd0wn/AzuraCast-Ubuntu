#CLEANUP UTILITY - AZURACAST STANDALONE UBUNTU SERVER VERSION

supervisorctl stop all || :

apt purge -y audiowaveform

apt purge -y liquidsoap

apt purge -y icecast2

apt purge -y composer

apt purge -y dbip

apt purge -y npm

apt purge -y centrifugo

apt purge -y zstd

apt purge -y sftpgo

apt purge -y php

apt purge -y mysql

apt purge -y tmpreaper

apt purge -y nginx

apt purge -y supervisor

apt purge -y beanstalkd

apt purge -y golang

apt purge -y redis

apt purge -y mysql*

apt purge -y mysql-*

apt purge -y mariadb

apt purge -y mariadb*

apt purge -y mariadb-*

apt purge -y nginx*

apt purge -y nginx-*

apt purge -y cron

apt purge -y cron*

apt purge -y vorbis*

apt purge -y php-fpm*

apt purge -y tmpreaper

apt purge -y php*

apt-get autoremove

cd /root/azuracast_installer/

rm -rf /etc/cron.d/azuracast_user

rm -rf /etc/php/8.2/

rm -rf /etc/apt/sources.list.d/mariadb.list*

rm /root/azuracast_installer/azuracast_installer.log

rm /root/azuracast_installer/azuracast_installer_runned

rm /root/azuracast_installer/azuracast_details.txt

rm -rf /var/azuracast/

rm -rf /var/azuracast/azuracast_version.txt

rm -rf /tmp/install_beanstalkd/

rm -rf /tmp/icecast/

rm -rf /tmp/app_fastcgi_tmp/

rm -rf /var/lib/sftpgo

rm -rf /etc/sftpgo

rm -rf /etc/supervisor/supervisor.conf

rm -rf /etc/supervisor/

rm -rf /var/log/supervisor/

rm -rf /usr/local/bin/liquidsoap

rm -rf /usr/bin/liquidsoap

rm -rf /usr/local/bin/icecast

rm -rf /usr/lib/lv2/master_me-easy-presets.lv2

rm -rf /usr/lib/lv2/master_me.lv2/

rm -rf /mnt/STORAGE/STATIONS/*

apt update -y

apt autoremove -y

apt-get purge -y golang supervisor cron sftpgo redis nginx php icecast liquidsoap beanstalkd centrifugo mysql

apt autoremove -y

apt-get purge -y golang* nginx-* php* vorbis* mysql-* icecast* mariadb-* liquidsoap* beanstalkd* centrifugo* redis*

apt autoremove -y

apt update -y

userdel azuracast

groupdel azuracast

apt autoremove -y
