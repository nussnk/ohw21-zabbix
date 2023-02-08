### ohw21-zabbix

Запускаем ВМ
```
vagrant up
```
Обновляем apt и качаем curl:

```
apt update -y
apt install curl -y
```

Качаем репозиторий MariaDB и задаем версию 10.8

```
curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
bash mariadb_repo_setup --mariadb-server-version=10.8
```

скачаем wget, скачаем и установим репозиторий zabbix-а, усановим пакеты zabbix, mariadb
```
apt update && apt install wget -y
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb
dpkg -i zabbix-release_*debian11_all.deb
apt update -y
apt install vim zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y
apt install mariadb-server mariadb-client -y
systemctl enable --now mariadb
```
Создаем базу и пользователя zabbix с паролем ZabbixPass
```
mysql -u root <<EOF

  CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;
  GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost IDENTIFIED BY 'ZabbixPass';
  FLUSH PRIVILEGES;
EOF
```

разворачиваем структуру таблиц для zabbix
```
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uroot zabbix
```
восстанавливаем стуктуру таблиц и данные из созданного ранее тестового стенда с именным дашбордом и графиками
```
zcat /vagrant/zabbix.sql.gz | mysql -uroot zabbix
```
копируем конфиг заббикс сервера
```
cp /vagrant/zabbix_server.conf /etc/zabbix/zabbix_server.conf
```
копируем настройки веб интерфейса
```
cp /vagrant/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
```
задаем корректного владельца файла
```
chown www-data:www-data /etc/zabbix/web/zabbix.conf.php
```
ставим пакеты для веб интерфейса заббикса
```
apt install zabbix-frontend-php zabbix-apache-conf
```
копируем преднастроенный php.ini
```
cp /vagrant/php.ini /etc/php/7.4/apache2/php.ini
```
копируем файл локалей для корректного отображения теста в веб интерфейсе
```
cp /vagrant/locale.gen /etc/locale.gen
```
генерируем необходимые файлы
```
locale-gen
```
перезапускаем сервис apache2
```
systemctl restart apache2
```
задаем автозапуск заббикс сервера, агента и веб сервера и перезапускам эти сервисы
```
systemctl enable zabbix-server zabbix-agent apache2
systemctl restart zabbix-server zabbix-agent apache2
```
Небольшой вывод в конце провиженинга с подсказкой что делать дальше
```
echo "======================================================================="
echo "======================================================================="
echo "== now check if zabbix is running visiting your_ip/zabbix"
echo "== your ip addresses are: `ip a | grep inet | grep -v inet6| grep -v 127.0.0.1`"
echo "== login: Admin"
echo "== password: zabbix"
echo "======================================================================="
echo "======================================================================="
```

