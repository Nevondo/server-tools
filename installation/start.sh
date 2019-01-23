#!/bin/bash

### Variables ###
TMP = "/tmp" 
CHECK_MK = "https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/check-mk-agent_1.5.0p9-1_all.deb"
BASHRC = "https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/.bashrc"
SSH_KEYS = "https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/authorized_keys"

### Functions ###
function CheckRootUser {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
}

function Update {
    apt update
    apt dist-upgrade -y
    apt autoremove -y
}

function InstallPackages {
    apt install aptitude molly-guard htop iftop parted tree vim curl screen screenfetch net-tools byobu xinetd -y
}

function SetupMonitoring {
    wget $CHECK_MK -O ${TMP}/check-mk-agent_1.5.0p9-1_all.deb
    dpkg -i ${TMP}/check-mk-agent_1.5.0p9-1_all.deb
}

function SetupScreenfetch {
    if ! grep --quiet screenfetch /etc/profile; then 
        echo screenfetch >> /etc/profile
    fi
}

function SetupBashrc {
    rm .bashrc
    wget $BASHRC -O .bashrc
}

function SetupSsh {
	mkdir /root/.ssh/
	wget $SSH_KEYS -O /root/.ssh/authorized_keys
    sed -i "/^[#?]*PasswordAuthentication[[:space:]]/c\PasswordAuthentication no" /etc/ssh/sshd_config
    systemctl restart ssh
}

function CleanUp {
    rm /etc/motd -f
    rm /etc/update-motd.d/* -R -f
    rm ${TMP}/check-mk-agent_1.5.0p9-1_all.deb
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
