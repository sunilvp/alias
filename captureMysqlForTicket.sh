#!/bin/bash

if [[ -z $1 || -z $2 ]]; then
	echo "No options passed, $1:tar_file_name $2:destination_folder"
	exit 1
fi
COLLECT_DIR=/tmp/for-percona
COLLECT_PROXYSQL_DIR=$COLLECT_DIR/proxysql
COLLECT_MYSQL_DIR=$COLLECT_DIR/mysql
COLLECT_PTDEST=$COLLECT_MYSQL_DIR/$(hostname)/

mkdir -p $COLLECT_DIR
mkdir -p $COLLECT_PROXYSQL_DIR
mkdir -p $COLLECT_MYSQL_DIR
mkdir -p $COLLECT_PTDEST

#mysql log capture
MY_CNF=/etc/my.cnf
MY_LOG=/var/lib/mysql/mysqld.log*

cp $MY_CNF $COLLECT_MYSQL_DIR/
cp $MY_LOG $COLLECT_MYSQL_DIR/
mysql --user=root --password="$ENV_MYSQL_ROOT_PWD" -e "SHOW ENGINE INNODB STATUS\G" > $COLLECT_MYSQL_DIR/innodb_status;
mysql --user=root --password="$ENV_MYSQL_ROOT_PWD" -e "SHOW FULL PROCESSLIST\G" > $COLLECT_MYSQL_DIR/processlist;
lsof -i:3306 >> $COLLECT_MYSQL_DIR/lsof_3306.txt
ps -aef | grep mysql >> $COLLECT_MYSQL_DIR/mysql.txt

#pt-stalk commands
pt-summary >> $PTDEST/pt-summary.out;
pt-mysql-summary -- --user=root --password="$ENV_MYSQL_ROOT_PWD" >> $COLLECT_PTDEST/pt-mysql-summary.out;
pt-stalk --no-stalk --iterations=2 --sleep=30 --dest=$COLLECT_PTDEST -- --user=root --pass=;
pt-pmp --save-samples=$COLLECT_PTDEST/pmp-full.txt
cp /var/log/messages  $MY_CNF $COLLECT_MYSQL_DIR/
dmesg > $COLLECT_MYSQL_DIR/dmest.txt
dmesg -T > $COLLECT_MYSQL_DIR/dmesg_t.txt

#proxysql logs capture
PROXY_ADMIN=/etc/proxysql-admin.cnf
cp $PROXY_ADMIN $COLLECT_PROXYSQL_DIR/
cp /var/lib/proxysql/* $COLLECT_PROXYSQL_DIR/
cp /usr/bin/proxysql_galera_checker $COLLECT_PROXYSQL_DIR/
cp /usr/bin/proxysql_node_monitor $COLLECT_PROXYSQL_DIR/
lsof -i:6032 >> $COLLECT_PROXYSQL_DIR/lsof_6032.txt
lsof -i:6033 >> $COLLECT_PROXYSQL_DIR/lsof_6033.txt
ps -aef | grep proxysql >> $COLLECT_PROXYSQL_DIR/ps_proxysql.txt

cd $COLLECT_DIR
tar -cvzf proxysql.tar.gz $COLLECT_PROXYSQL_DIR
tar -cvzf mysql.tar.gz $COLLECT_MYSQL_DIR
tar -cvzf $COLLECT_DIR/forPercona_$1.tar.gz $COLLECT_DIR/proxysql.tar.gz $COLLECT_DIR/mysql.tar.gz

sshpass -p mainstreet scp -o "StrictHostKeyChecking no" -r forPercona_$1.tar.gz root@135.227.176.66:$2 
