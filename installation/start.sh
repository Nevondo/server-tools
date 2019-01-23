#!/bin/bash

### Variables ###
TMP="/tmp" 
CHECK_MK="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/check-mk-agent_1.5.0p9-1_all.deb"
BASHRC="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/.bashrc"
SSH_KEYS="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/authorized_keys"

### Functions ###
function CheckRootUser {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
}

function Update {
    apt update &>/dev/null
    apt dist-upgrade -y &>/dev/null
    apt autoremove -y &>/dev/null
}

function InstallPackages {
    apt install aptitude molly-guard htop iftop parted tree vim curl screen screenfetch net-tools byobu xinetd -y &>/dev/null
}

function SetupMonitoring {
    wget $CHECK_MK -O ${TMP}/check-mk-agent_1.5.0p9-1_all.deb &>/dev/null
    dpkg -i ${TMP}/check-mk-agent_1.5.0p9-1_all.deb &>/dev/null
}

function SetupScreenfetch {
    if ! grep --quiet screenfetch /etc/profile; then  &>/dev/null
        echo screenfetch >> /etc/profile &>/dev/null
    fi
}

function SetupBashrc {
    rm .bashrc &>/dev/null
    wget $BASHRC -O .bashrc &>/dev/null
}

function SetupSsh {
	mkdir /root/.ssh/ &>/dev/null
	wget $SSH_KEYS -O /root/.ssh/authorized_keys &>/dev/null
    sed -i "/^[#?]*PasswordAuthentication[[:space:]]/c\PasswordAuthentication no" /etc/ssh/sshd_config &>/dev/null
    systemctl restart ssh &>/dev/null
}

function CleanUp {
    rm /etc/motd -f &>/dev/null
    rm /etc/update-motd.d/* -R -f &>/dev/null
    rm ${TMP}/check-mk-agent_1.5.0p9-1_all.deb &>/dev/null
}

function SetRootPassword {
    pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
    echo "root:$pw" | chpasswd
    echo "********************************"
    echo "       New root password        "
    echo "$pw"
    echo "********************************"
}

### Main ###
CheckRootUser
Update
InstallPackages
SetupMonitoring
SetupScreenfetch
SetupBashrc
SetupSsh
CleanUp
SetRootPassword
