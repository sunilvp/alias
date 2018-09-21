#!/bin/bash
myenv ( )
{
	export PYTHONPATH=$PYTHONPATH:'/opt/vsd/sysmon':'/opt/vsd/redundancy/':'/opt/vsd/password/'
	if [ -r /opt/vsd/install/vsd_password.ini ] \
	        && [ -x /opt/vsd/password/passwordParser.py ] \
	        && python /opt/vsd/password/passwordParser.py -v >> /opt/vsd/logs/install.log 2>&1 ; then
	    :
	   eval $(python /opt/vsd/password/passwordParser.py 2>> /opt/vsd/logs/install.log)
	else
	   echo "ERROR: vsd-deploy, Failed to use the password file please check if file and permission exists"
	fi
}

function getPid() {
	if [[ $1 == "amq" || $1 == "a" || $1 == "activemq" ]]; then
		echo "Activemq Pid:"
		printPid "activemq.jar start"
		echo "Pid Details:"
		printPidDetails "activemq.jar start"
    elif [[ $1 == "jboss" || $1 == "j" ]]; then
    	echo "Jboss Pid:"
		printPid "jboss.server.base.dir=/opt/vsd/jboss/standalone"
		echo "Pid Details:"
		printPidDetails "jboss.server.base.dir=/opt/vsd/jboss/standalone"
	elif [[ $1 == "ej" || $1 == "ejabberd" || $1 == "e" ]]; then
		echo "Ejabberd Pid:"
		printPid "/opt/ejabberd/bin/beam.smp"
		echo "Pid Details:"
		printPidDetails "/opt/ejabberd/bin/beam.smp"
	elif [[ $1 == "tca" ]]; then
		echo "TCA Pid:"
		printPid "AREServer"
		echo "Pid Details:"
		printPidDetails "AREServer"
	elif [[ $1 == "stats" ]]; then
		echo "Stats Pid:"
		printPid "StatsCollectorServer"
		echo "Pid Details:"
		printPidDetails	"StatsCollectorServer"
	elif [[ $1 == "key" || $1 == "keyserver" || $1 == "k" ]]; then
		echo "Keyserver Pid:"
		printPid "KeyServerController"
		echo "Pid Details:"
		printPidDetails "KeyServerController"
	elif [[ $1 == "infi" || $1 == "i" ]]; then
		echo "Infinispan Pid:"
		printPid "infinispan/modules"
		echo "Pid Details:"
		printPidDetails	"infinispan/modules"
	elif [[ $1 == "med" || $1 == "mediator" || $1 == "m" ]]; then
		echo "Mediator Pid:"
		printPid "MediationController"
		echo "Pid Details:"
		printPidDetails	"MediationController"
	elif [[ $1 == "proxysql" || $1 == "p" ]]; then
		echo "Proxysql Pid:"
		printPidParentPidName "/usr/bin/proxysql -c /etc/proxysql.cnf -D /var/lib/proxysql"
		echo "Pid Details:"
		printPidDetails "/usr/bin/proxysql -c /etc/proxysql.cnf -D /var/lib/proxysql"
	elif [[ $1 == "mysql" || $1 == "y" ]] \
		&& [[ -f /var/run/mysql/mysql.pid ]]; then
		echo "Mysql Pid:"
		cat /var/run/mysql/mysql.pid
		echo "Pid Details:"
		ps -aef | grep `cat /var/run/mysql/mysql.pid` | grep -v grep
	elif [[ $1 == "zoo" || $1 == "z" ]] \
		&& [[ -f /var/run/zookeeper/zookeeper-server.pid ]]; then
		echo "zookeeper Pid:"
		cat /var/run/zookeeper/zookeeper-server.pid
		echo "Pid Details:"
		ps -aef | grep `cat /var/run/zookeeper/zookeeper-server.pid` | grep -v grep
 	fi
}

function printPid() {
	ps -aef | grep "$1" | grep -v grep | awk '{print "\t" $2}'
}

function printPidDetails() {
	ps -aef | grep "$1" | grep -v grep
}

function printPidParentPidName() {
	ps -aef | grep "$1" | grep -v grep | awk '{print "\t" $2 "\t" $3}'
}

#alias
alias lvs='clear; tail -1000f /opt/vsd/jboss/standalone/log/server.log'
alias lvv='clear; tail -1000f /opt/vsd/jboss/standalone/log/vsdserver.log'
alias lvx='clear; tail -1000f /opt/vsd/jboss/standalone/log/xmpp-conn.log'
alias lvk='clear; tail -1000f /opt/vsd/jboss/standalone/log/keyserver.log'
alias lz='clear; tail -1000f /opt/vsd/jboss/standalone/log/zfb.log'
alias lvm='clear; tail -1000f /opt/vsd/mediator/cna-mediator.log'
alias lmonit='clear; tail -1000f /var/log/monit.log'
alias lmysql='clear; tail -1000f /var/lib/mysql/mysqld.log'
alias linstall='clear; tail -1000f /opt/vsd/logs/install.log'
alias ldecouple='clear; tail -1000f /opt/vsd/logs/patch.log'
alias le='clear; tail -1000f /opt/ejabberd/logs/ejabberd.log'

#monit stop start restart
alias mssj='monit stop jboss'
alias msj='monit start jboss'
alias mssa='monit stop activemq'
alias msa='monit start activemq'
alias mrj='monit restart jboss'
alias mssm='monit stop mediator'
alias msm='monit start mediator'
alias mrm='monit restart mediator'
alias mssc='monit stop -g vsd-core'
alias msc='monit start -g vsd-core'
alias mssco='monit stop -g vsd-common'
alias msco='monit start -g vsd-common'
#monit check
alias mcj='/opt/vsd/sysmon/jbossStatus.py'
alias mcm='/opt/vsd/sysmon/mediatorStatus.py'
alias mcp='/opt/vsd/sysmon/proxysqlStatus.sh'
alias mcy='/opt/vsd/sysmon/perconaStatus.py'
alias mce='echo "EjabberdStatus: ";/opt/vsd/sysmon/ejabberdStatus.py'
alias mcas='/opt/vsd/sysmon/activemqStatus.py'
alias mca='/opt/vsd/sysmon/activemqStatus.py -c'
alias mcej='echo "EjbcaStatus:"; /opt/vsd/sysmon/ejbca-status.py'
alias mrntp='date; service ntpd stop ; sleep 1 ; service ntpd start ; date; watch ntpstat'

alias cmysql='echo "check Mysql :"; mysql -e "select 1"'
alias vpass='cat /opt/vsd/install/vsd_password.ini'
alias vmonit='monit summary'

#proxysql check commands
alias psql='function _proxysql(){ myenv ;mysql -u admin -p$ENV_VSD_PROXYSQLPWD -h 127.0.0.1 -P 6032 -e "$1"; }; _proxysql'
alias pmysql='function _proxyMysql(){ myenv ;mysql -u cnauser -p$ENV_VSD_CNAPWD -P 6033 -e "$1"; }; _proxyMysql'
alias pser='myenv ;mysql -u admin -p$ENV_VSD_PROXYSQLPWD -h 127.0.0.1 -P 6032 -e "select * from runtime_mysql_servers order by hostgroup_id"'
alias psche='myenv ;mysql -u admin -p$ENV_VSD_PROXYSQLPWD -h 127.0.0.1 -P 6032 -e "select * from scheduler"'
alias pusers='myenv ;mysql -u admin -p$ENV_VSD_PROXYSQLPWD -h 127.0.0.1 -P 6032 -e "select * from runtime_mysql_users"'
alias prules='myenv ;mysql -u admin -p$ENV_VSD_PROXYSQLPWD -h 127.0.0.1 -P 6032 -e "select * from runtime_mysql_query_rules"'
alias pconpool='myenv ;mysql -u admin -p$ENV_VSD_PROXYSQLPWD -h 127.0.0.1 -P 6032 -e "select * from stats_mysql_connection_pool"'
alias lproxy="clear; tail -1000f /var/lib/proxysql/proxysql.log"
alias vphost="cat /var/lib/proxysql/host_priority.conf"
alias vpadmin="cat /etc/proxysql-admin.cnf"
alias plite="sqlite3 /var/lib/proxysql/proxysql.db"
alias yboot="/opt/vsd/sysmon/bootPercona.py --force"
alias ywstatus="mysql -e \"select * from information_schema.GLOBAL_STATUS where VARIABLE_NAME LIKE 'wsrep_ready' OR VARIABLE_NAME LIKE 'wsrep_incoming_addresses' OR VARIABLE_NAME LIKE 'wsrep_cluster_size' OR VARIABLE_NAME LIKE 'wsrep_local_state' OR VARIABLE_NAME LIKE 'wsrep_local_state_comment'\""


#ejabberd
alias estatus='/opt/ejabberd/bin/ejabberdctl status'
alias eusers='/opt/ejabberd/bin/ejabberdctl connected_users'
alias elistc='/opt/ejabberd/bin/ejabberdctl list_cluster'
alias elistp='/opt/ejabberd/bin/ejabberdctl list_p1db'
alias eslog='/opt/ejabberd/bin/ejabberdctl set_loglevel 5'
alias esslog='/opt/ejabberd/bin/ejabberdctl set_loglevel 3'

#xmpp-tool
alias xnodes='/opt/vsd/tools/xmpp_client.py nodes'
alias xping='/opt/vsd/tools/xmpp_client.py -u cna -p cnauser -t ping subscriptions'
alias xcnajid='/opt/vsd/tools/xmpp_client.py -t cna_discover_jid nodes'

alias iopen='function _iptables(){ iptables -I INPUT -p tcp -m tcp --dport $1 -j ACCEPT ;}; _iptables'

alias pid='getPid $1'
