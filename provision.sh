#!/bin/bash

apt update -y
apt install curl -y

curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup

bash mariadb_repo_setup --mariadb-server-version=10.8

apt update && apt install wget -y

wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb

dpkg -i zabbix-release_*debian11_all.deb

apt update -y
apt install vim zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y

apt install mariadb-server mariadb-client -y
systemctl enable --now mariadb
echo 'mysql -u root create db'
mysql -u root <<EOF

  CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;
  GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost IDENTIFIED BY 'ZabbixPass';
  FLUSH PRIVILEGES;
EOF

echo 'zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -pZabbixPass zabbix'
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uroot zabbix
echo 'mysql -uroot zabbix < /vagrant/zabbix.sql'
zcat /vagrant/zabbix.sql.gz | mysql -uroot zabbix

cp /vagrant/zabbix_server.conf /etc/zabbix/zabbix_server.conf
cp /vagrant/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
chown www-data:www-data /etc/zabbix/web/zabbix.conf.php

apt install zabbix-frontend-php zabbix-apache-conf

cp /vagrant/php.ini /etc/php/7.4/apache2/php.ini
cp /vagrant/locale.gen /etc/locale.gen
locale-gen

systemctl restart apache2

systemctl enable zabbix-server zabbix-agent apache2
systemctl restart zabbix-server zabbix-agent apache2
echo "now check if zabbix is running visiting your_ip/zabbix"
echo "your ip addresses are: `ip a | grep inet | grep -v inet6| grep -v 127.0.0.1`"
