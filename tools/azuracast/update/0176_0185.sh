#!/usr/bin/env bash

##############################################################################
# This will update AzuraCast 0.17.6 Stable to 0.18.5 Stable
# This will only work if you previously used this installer for version 0.17.6 Stable.
##############################################################################

### Config
newVersion=0.18.5

### Prepare
# Ask the user if they are sure and have a backup
echo -e "\n\n---\n\n"
read -rp "Do you have a backup of your installation? (yes or no): " yn_one
echo
read -rp "Do you really want to upgrade to AzuraCast Stable $newVersion? (yes or no): " yn_two

# Check answers
if [[ "$yn_one" == "yes" || "$yn_one" == "scy" ]] && [[ "$yn_two" == "yes" || "$yn_two" == "scy" ]]; then
    echo
    echo "Upgrade will start now. I am lazy, so no logs this time like you have in the installation process."
    echo
else
    echo "Error: Your answers were not correct."
    exit 1
fi

# Function to check for dpkg lock and wait until it's released or timeout occurs
wait_for_dpkg_lock() {
    local timeout=120
    local start_time=$(date +%s)
    while pgrep -f 'dpkg\.lock-frontend|apt' >/dev/null; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        if ((elapsed_time >= timeout)); then
            echo "Timeout: Unable to acquire dpkg lock after $timeout seconds. Exiting..."
            exit 1
        fi
        echo 'Lock file is in use. Waiting 3 seconds...'
        sleep 3
    done
}

# Wrapper function for apt-get that handles the lock check
apt_get_with_lock() {
    wait_for_dpkg_lock
    apt-get "$@"
}

### AzuraCast related
# Check if the user started the right upgrade script
azv=/var/azuracast/www/src/Version.php
if [ -f "$azv" ]; then
    FALLBACK_VERSION="$(grep -oE "FALLBACK_VERSION = '.*';" "$azv" | sed "s/FALLBACK_VERSION = '//g;s/';//g")"
    echo -e "AzuraCast Version $FALLBACK_VERSION will be upgraded to $newVersion\n"

    if [ "$FALLBACK_VERSION" != "0.17.6" ]; then
        echo "Invalid AzuraCast version. Exiting the script."
        exit 1
    fi
fi

# Backup AzuraCast DB
chmod +x /var/azuracast/www/bin/console
/var/azuracast/www/bin/console azuracast:backup $installerHome/tools/azuracast/update/backup/$FALLBACK_VERSION.zip
echo -e "Backup of $FALLBACK_VERSION is located in $installerHome/tools/azuracast/update/backup/$FALLBACK_VERSION.zip\n"

### Update System
# First, we have to check if anything is up to date
export DEBIAN_FRONTEND=noninteractive
apt_get_with_lock update
apt_get_with_lock upgrade -y

### Stop Services
# Stop Zabbix (Only internal, but it will not disturb users who used this installer.)
systemctl stop zabbix-agent || :

# Stop all supervisor processes
supervisorctl stop all || :

### Update PHP to 8.2 (0.17.6 was using 8.1)
PHP_VERSION=8.2
PHP_DIR=/etc/php/${PHP_VERSION}
PHP_POOL_DIR=$PHP_DIR/fpm/pool.d
PHP_MODS_DIR=$PHP_DIR/mods-available
PHP_RUN_DIR=/run/php

# Install PHP packages and required dependencies
apt_get_with_lock install -y curl php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-gd \
    php${PHP_VERSION}-curl php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bcmath php${PHP_VERSION}-gmp php${PHP_VERSION}-mysqlnd \
    php${PHP_VERSION}-mbstring php${PHP_VERSION}-intl php${PHP_VERSION}-redis \
    php${PHP_VERSION}-maxminddb php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-dev zlib1g-dev build-essential

# Set PHP version
echo "PHP_VERSION=$PHP_VERSION" >>/etc/php/.version

# Create required directories and files
mkdir -p $PHP_RUN_DIR
touch $PHP_RUN_DIR/php${PHP_VERSION}-fpm.pid

# Copy PHP configuration files
curl -s -o $PHP_POOL_DIR/php.ini https://raw.githubusercontent.com/ashd0wn/AzuraCast-Ubuntu/$newVersion/web/php/php.ini
curl -s -o $PHP_POOL_DIR/www.conf https://raw.githubusercontent.com/ashd0wn/AzuraCast-Ubuntu/$newVersion/web/php/www.conf

# Copy Supervisors php-fpm.conf
curl -s -o /etc/supervisor/conf.d/php-fpm.conf https://raw.githubusercontent.com/ashd0wn/AzuraCast-Ubuntu/$newVersion/supervisor/conf.d/php-fpm.conf

# Disable and stop PHP FPM because of Supervisor
systemctl disable php8.1-fpm
systemctl stop php8.1-fpm
systemctl disable php${PHP_VERSION}-fpm
systemctl stop php${PHP_VERSION}-fpm

# Set the default system PHP version to the one we want
update-alternatives --set php /usr/bin/php${PHP_VERSION}

### Redis is new in this version
# Install Redis
apt_get_with_lock install -y --no-install-recommends redis-server

# Get redis.conf
curl -s -o /etc/redis/redis.conf https://raw.githubusercontent.com/ashd0wn/AzuraCast-Ubuntu/$newVersion/redis/redis.conf
chown redis.redis /etc/redis/redis.conf

# Get supervisor redis.conf
curl -s -o /etc/supervisor/conf.d/redis.conf https://raw.githubusercontent.com/ashd0wn/AzuraCast-Ubuntu/$newVersion/supervisor/conf.d/redis.conf

# Stop Redis
systemctl disable redis-server || :
systemctl stop redis-server || :

### Add master_me
mkdir -p /tmp/master_me
cd /tmp/master_me

ARCHITECTURE=x86_64
if [[ "$(uname -m)" = "aarch64" ]]; then
    ARCHITECTURE=arm64
fi

wget -O master_me.tar.xz "https://github.com/trummerschlunk/master_me/releases/download/1.2.0/master_me-1.2.0-linux-${ARCHITECTURE}.tar.xz"

tar -xvf master_me.tar.xz --strip-components=1

mkdir -p /usr/lib/ladspa
mkdir -p /usr/lib/lv2

mv ./master_me-easy-presets.lv2 /usr/lib/lv2
mv ./master_me.lv2 /usr/lib/lv2
mv ./master_me-ladspa.so /usr/lib/ladspa/master_me.so

cd $installerHome

### Now it's time for AzuraCast
# ups :p
rm -rf /var/azuracast/www_tmp/*

# Better do it as the AzuraCast User
if [ $yn_one = "yes" ]; then
    su azuracast <<'EOF'
cd /var/azuracast/www
git stash
git pull
git checkout 0.18.5-org
cd /var/azuracast/www/frontend
export NODE_ENV=production
npm ci
npm run build
EOF
else
    su azuracast <<'EOF'
cd /var/azuracast/www
git stash
git pull
git checkout 0.18.5-scy
cd /var/azuracast/www/frontend
export NODE_ENV=production
npm ci
npm run build
EOF
fi

# NPM Build
#cd /var/azuracast/www/frontend
#export NODE_ENV=production
#npm ci
#npm run build

# Back to InstallerHome
cd $installerHome

# Read new config files
supervisorctl reread
supervisorctl update
supervisorctl restart redis

# Migrate Database
chmod +x /var/azuracast/www/bin/console
/var/azuracast/www/bin/console azuracast:setup:migrate

# Remove
rm -f /var/azuracast/installer_version.txt

# Update Version (Not needed actually this file. But leave it for now)
rm -f /var/azuracast/azuracast_version.txt
echo "$newVersion" >/var/azuracast/azuracast_version.txt

# Error on one Testrun. Not sure where it occurs. But command makes no difference and fix it
chown -R azuracast.azuracast /var/azuracast/www*
