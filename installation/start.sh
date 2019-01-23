#!/bin/bash

### Functions ###
function CheckRootUser {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
}

function Install {
    apt update
    apt dist-upgrade -y
    apt install aptitude molly-guard htop iftop parted tree vim curl screen screenfetch net-tools byobu -y
    if ! grep --quiet screenfetch /etc/profile; then 
        echo screenfetch >> /etc/profile
    fi
    rm .bashrc
    wget https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/.bashrc -O .bashrc
	mkdir /root/.ssh/
	wget https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/authorized_keys -O /root/.ssh/authorized_keys
    rm /etc/motd -f
    rm /etc/update-motd.d/* -R -f
    sed -i "/^[#?]*PasswordAuthentication[[:space:]]/c\PasswordAuthentication no" /etc/ssh/sshd_config
    systemctl restart ssh
}

function resetPassword {
    pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
    echo "root:$pw" | chpasswd
    echo "********************************"
    echo "       New root password        "
    echo "$pw"
    echo "********************************"
}

### Main ###
CheckRootUser
Install
resetPassword
