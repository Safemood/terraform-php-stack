#!/bin/bash 

# $1 is mysql_root_password
# $2 is db_name
# $3 is db_user
# $4 is db_password


export DEBIAN_FRONTEND="noninteractive" 
export NEEDRESTART_MODE=a


sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password "$1""
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password "$1"" 

sudo apt-get install -y mysql-server

sudo mysql -uroot -p$1 -e "CREATE DATABASE $2 /*\!40100 DEFAULT CHARACTER SET utf8 */;"
sudo mysql -uroot -p$1 -e "CREATE USER $3@localhost IDENTIFIED BY '$4';"
sudo mysql -uroot -p$1 -e "GRANT ALL PRIVILEGES ON $2.* TO '$3'@'localhost';"
sudo mysql -uroot -p$1 -e "FLUSH PRIVILEGES;"

sudo mysql -u root -p$1 -e "DELETE FROM mysql.user WHERE User=\'\'; DELETE FROM mysql.user WHERE User=\'root\' AND Host NOT IN (\'localhost\', \'127.0.0.1\', \'::1\'); DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;",
cat /dev/null > ~/.bash_history && history -c



