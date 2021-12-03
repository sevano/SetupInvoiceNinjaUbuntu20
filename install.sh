#!/bin/bash

echo "Choose your root database password: "
read dbpass

echo "Domain name for https: (Assign domain to ip before proceeding)"
read domain



apt-get update
apt install software-properties-common -y

echo "deb [arch=arm64,ppc64el,amd64] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.3/ubuntu focal main" > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
apt-get update

export DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $dbpass"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $dbpass"

#update
apt-get update
apt install php-{fpm,bcmath,ctype,fileinfo,json,mbstring,pdo,tokenizer,xml,curl,zip,gmp,gd,mysqli} -y
apt install php mariadb-server nginx curl certbot git -y



#remove nginx stuff
rm /var/www/html/index.nginx-debian.html
rm /etc/nginx/sites-enabled/default


cat << 'EOF' > /etc/nginx/sites-enabled/invoiceninja.conf
 server {
   listen       443 ssl http2 default_server;
   listen       [::]:443 ssl http2 default_server;
   server_name  REPLACETHIS;
   client_max_body_size 20M;

   if ($host != $server_name) {
     return 301 https://$server_name$request_uri;
   }

   root /var/www/invoiceninja/public;

   gzip on;
   gzip_types application/javascript application/x-javascript text/javascript text/plain application/xml application/json;
   gzip_proxied    no-cache no-store private expired auth;
   gzip_min_length 1000;

   index index.php index.html index.htm;

   ssl_certificate "/etc/letsencrypt/live/REPLACETHIS/fullchain.pem";
   ssl_certificate_key "/etc/letsencrypt/live/REPLACETHIS/privkey.pem";

   ssl_session_cache shared:SSL:1m;
   ssl_session_timeout  10m;
   ssl_ciphers 'AES128+EECDH:AES128+EDH:!aNULL';
   ssl_prefer_server_ciphers on;
   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

   charset utf-8;
   include /etc/nginx/default.d/*.conf;

   location / {
       try_files $uri $uri/ /index.php?$query_string;
   }

   if (!-e $request_filename) {
           rewrite ^(.+)$ /index.php?q= last;
   }

   location ~ \.php$ {
           fastcgi_split_path_info ^(.+\.php)(/.+)$;
           fastcgi_pass unix:/run/php/php7.4-fpm.sock;
           fastcgi_index index.php;
           include fastcgi_params;
           fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
           fastcgi_intercept_errors off;
           fastcgi_buffer_size 16k;
           fastcgi_buffers 4 16k;
   }

   location ~ /\.ht {
       deny all;
   }

   location = /favicon.ico { access_log off; log_not_found off; }
   location = /robots.txt { access_log off; log_not_found off; }

   access_log /var/log/nginx/REPLACETHIS.access.log;
   error_log /var/log/nginx/REPLACETHIS.error.log;

   sendfile off;

  }

  server {
      listen      80;
      server_name REPLACETHIS;
      add_header Strict-Transport-Security max-age=2592000;
      rewrite ^ https://$server_name$request_uri? permanent;
  }
EOF

sed -i "s/REPLACETHIS/$domain/g" "/etc/nginx/sites-enabled/invoiceninja.conf"


cd /tmp/
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer


cd /var/www/
git clone https://github.com/invoiceninja/invoiceninja
cd invoiceninja
git checkout v5-stable
cp .env.example .env
export COMPOSER_ALLOW_SUPERUSER=1; composer show;
composer install
chown -R www-data:www-data /var/www
chmod -R 777 storage

php artisan key:generate
php artisan optimize

service nginx stop
certbot certonly --standalone -d  $domain  --register-unsafely-without-email --agree-tos

certbot certonly --standalone -d  zaki.mypanel.cc  --register-unsafely-without-email --agree-tos
service nginx start

#mysql --user=root --password=$dbpass -s --execute="create database ninjadb;"
#mysql --user=root --password=$dbpass -s --execute="create user 'ninjadb'@'localhost' identified by '123456';"
#mysql --user=root --password=$dbpass -s --execute="grant all privileges on ninjadb.* to 'ninjadb'@'localhost';"
#mysql --user=root --password=$dbpass -s --execute="flush privileges;"

echo "########################"
echo "run command: mysql -u root -p"
echo "write your database root password to login"
echo "command: create database ninjadb;"
echo "command: create user 'ninjadb'@'localhost' identified by 'YOUR_NINJADB_DB_PASS';"
echo "command: grant all privileges on ninjadb.* to 'ninjadb'@'localhost';"
echo "command: flush privileges;"
echo "go on your browser to https://Your_Domain/setup | setup you need to do 2 times"
