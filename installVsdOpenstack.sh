#!/bin/bash

#
#  Script to setup the machines from openstack.
#  If $2 is empty then will perform the operations with Alcateldc credentials. 
#  Sets hostname, ntp 
#  ./scriptName ipaddress <password to use>
#  
#


# Checks the return value of the most recent command
#
# Globals:
#   None
#
# Arguments:
#   1: the error code of the most recent command
#   2: the error message if the error code is non-zero
#
# Exits the script if the retcode is non-zero.
#
check_cmd(){
  MPID=$1
  ERROR_MSG=$2
  if [ "${MPID}" -ne 0 ]; then echo -e "\nERROR: $ERROR_MSG. Terminating!"; exit 1; fi
}
#
# Execute command on the remote machine
# $1 command to be executed
#
function executeOnRemoteWithFailure()
{
    sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ipAddr} "$1"
    check_cmd $? "Failed to execute SSH command, or returned exit code"
}

#
# Check if the SSH connection is good and exit on failure
#
function checkSSH()
{
    executeOnRemoteWithFailure "date"
}

#
# Execute command on the remote machine
# $1 command to be executed
#
function executeOnRemote()
{
    sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ipAddr} "$1"
}

#
# Scp $1 file to ${ipAddr} to $2 location on remote machine
#
function scpToRemote()
{
    sshpass -e scp -q -o GSSAPIAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $1  root@${ipAddr}:$2
}

#
# Check if the ping to machine is working fine
#
function checkNetwork() {
	ping -c1 -W 3 ${ipAddr} > /dev/null
    check_cmd $? "Unable to ping ${ipAddr}"
}

#
# set the hostname field and edit the /etc/hosts
# ipAddr : to add in the /etc/hosts file.
#
function setHostname()
{
    #fetch the current hostname.
    nameHost=$(executeOnRemote hostname)
    echo $nameHost
    executeOnRemote "hostnamectl set-hostname ${nameHost}"

    contentsOfHost=$(executeOnRemote "cat /etc/hosts")
    
    #if entry is already present then no need to add one more.
    #delimeter as new line check if hosts entry is already there.
    IFS=$'\n'
    found="False"
    for line in ${contentsOfHost}
    do
        if [[ $line == *"${nameHost}"* ]];then
            found="True"
            break
        fi
    done

    if [ ${found} != "True" ];then
        executeOnRemote "echo -e \"${ipAddr}\t${nameHost}\" >> /etc/hosts"
    fi
}

#
#Check if hostname and hostname -f returns same
#
function checkHostnameIsProper()
{
    nameHost=$(executeOnRemote hostname)
    nameHostF=$(executeOnRemote "hostname -f")

    if [[ ${nameHost} != ${nameHostF} ]];then
        echo "ERROR: hostname:${nameHost} and hostname -f :${nameHostF} doesn't match"
        exit 2
    fi
}

#
# Check if the ntp is working fine if not restart it. 
#
#
function checkAndSetNtp()
{
    executeOnRemote "mycount=0;while [[ \"\$mycount\" -lt 10 ]];do ((mycount++));echo \"waiting...$mycount\";sleep 1;if ntpstat;then echo \"good\";exit 0;else echo \"exit code $? ; retry $mycount\";fi;done; echo \"timed out\";exit 1"
    if [ $? -ne 0 ]; then
        restartNtp
    fi
}

#
# Restart the ntp service. 
#
function restartNtp()
{
    executeOnRemote "service ntpd restart"
    sleep 30
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to restart ntp"
        exit 1
    fi
}

#
# Copy my latest alias to the remote machine
#
function aliasCopy()
{
    timeout 5 wget https://raw.githubusercontent.com/sunilvp/alias/master/alias.sh  -O /tmp/aliases;
    scpToRemote /tmp/aliases /tmp/aliases
    executeOnRemote "chmod +x /tmp/aliases"
    executeOnRemote "echo -e \". /tmp/aliases\" >> ~/.bashrc"
}

#
# copy the debug commands to remote machine and execute the script
#
#
function debugCopy()
{
    timeout 10 wget https://raw.githubusercontent.com/sunilvp/scripts/master/debugEnable.sh -O /tmp/debugEnable.sh
    scpToRemote /tmp/debugEnable.sh /tmp/debugEnable.sh
    executeOnRemote "chmod +x /tmp/debugEnable.sh"
    executeOnRemote "/tmp/debugEnable.sh"
}


#$1 is the ipaddress of openstack machine which we have to set. 
ipAddr=$1

# Export the SSHPASS env variable so that ssh -e will use the password from this variable. 
SSHPASS_VALUE="Alcateldc"
if [ ! -z $2 ];then
    SSHPASS_VALUE=$2
fi
export SSHPASS=${SSHPASS_VALUE}
echo "Using ${SSHPASS} for executing on remote machienes"

#
# verify connection 
# ping check
# Set and check if NTP is proper
# Set the check hostname is properly configured. 
#
if checkSSH\
    && checkNetwork \
    && checkAndSetNtp \
    && setHostname \
    && checkHostnameIsProper \
    && aliasCopy\
    && debugCopy;then
    echo "INFO: Successfully executed"
else
    echo "Error: Failed to configure the machine ${ipAddr}"
fi
