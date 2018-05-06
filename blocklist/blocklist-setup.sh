#!/bin/bash

function checkDependencies {
	dpkg --get-selections | grep '^ipset' >/dev/null
    if [[ $? = 1 ]]; then
       apt-get install ipset -y
    fi

	dpkg --get-selections | grep '^xtables-addons-source' >/dev/null
    if [[ $? = 1 ]]; then
       apt-get install xtables-addons-source -y
    fi
	
	dpkg --get-selections | grep '^module-assistant' >/dev/null
    if [[ $? = 1 ]]; then
       apt-get install module-assistant -y
    fi
	
	dpkg --get-selections | grep '^perl' >/dev/null
    if [[ $? = 1 ]]; then
       apt-get install perl -y
    fi
}

function insertBlocklist {
    wget -O blocklist.pl https://git.hosted4u.de/Hosted4u/Security/raw/master/blocklist/blocklist.pl
    mv blocklist.pl /opt/blocklist.pl
    chmod +x /opt/blocklist.pl
}

function checkCron {
	if [ ! -f /etc/cron.hourly/blocklist ]; then
		echo "#!/bin/bash" >> /etc/cron.hourly/blocklist
		echo "/usr/bin/perl /opt/blocklist.pl >/dev/null 2>&1" >> /etc/cron.hourly/blocklist
		chmod +x /etc/cron.hourly/blocklist
	fi
}

if [ "`id -u`" != "0" ]; then
    echo "Wechsle zu dem Root Benutzer!"
    su root
	fi
if [ "`id -u`" != "0" ]; then
    echo "Nicht als Rootbenutzer ausgeführt, Abgebrochen!"
    exit
	fi

checkDependencies
insertBlocklist
checkCron
