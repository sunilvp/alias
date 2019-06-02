#!/bin/bash

### Utility scirpt to modify files to debug mode and start the application in DEBUG MODE and open up iptables rules

function _iptables()
{
iptables -I INPUT -p tcp -m tcp --dport $1 -j ACCEPT ;
}


function modifyMonit()
{
sed -i 's/set daemon  60/set daemon  30/' /etc/monitrc;
}

function debugJboss()
{
sed -i 's/DEBUG_MODE="${DEBUG:-false}"/DEBUG_MODE="${DEBUG:-true}"/' /opt/vsd/jboss/bin/standalone.sh;
sed -i 's/DEBUG_MODE=false/DEBUG_MODE=true/' /opt/vsd/jboss/bin/standalone.sh;
_iptables 8787
}

function debugMediator()
{
sed -i 's/DEBUG_MODE=false/DEBUG_MODE=true/' /etc/init.d/mediator.sh;
_iptables 5005
}

function debugKeyserver()
{
sed -i 's/DEBUG_MODE=false/DEBUG_MODE=true/' /opt/vsd/keyserver/bin/keyserver.sh;
_iptables 5006
}

modifyMonit
debugJboss
debugMediator
debugKeyserver


