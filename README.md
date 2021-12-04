# Setup Invoice Ninja for Ubuntu 20 

## Installation
cd /home/
wget https://raw.githubusercontent.com/sevano/SetupInvoiceNinjaUbuntu20/main/install.sh
chmod 755 install.sh
./install

1)You will need to give a database password which u want to setup during the installation

2)You will need a assign A record to the server ip on your domain as example hello.com or inv.hello.com and this will automaticly generate ssl with letsencrypt for that domain.

3)database part is not automated so you will need to do that manually.

```bash
mysql -u root -p
```

```bash
create database ninjadb;
```
```bash
create user 'ninjadb'@'localhost' identified by 'YOUR_NINJADB_DB_PASS';
```
```bash
grant all privileges on ninjadb.* to 'ninjadb'@'localhost';
```
```bash
flush privileges;
```
go on your browser to https://Your_Domain/setup | setup you need to do 2 times


This installation is quick made for the people who can't install invoiceninja 5. 
