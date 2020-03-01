#!/bin/bash

BACKUP_SERVER="backup01.nevondo.com"
CONFIG="https://git.nevondo.com/Nevondo/server-tools/raw/master/borgmatic/includes/config.yaml"
SERVICE="https://git.nevondo.com/Nevondo/server-tools/raw/master/borgmatic/includes/borgmatic.service"
TIMER="https://git.nevondo.com/Nevondo/server-tools/raw/master/borgmatic/includes/borgmatic.timer"
MAIL="https://git.nevondo.com/Nevondo/server-tools/raw/master/borgmatic/includes/mail.sh"



##
#
# Functions
#
##
function greenMessage {
    echo -e "\\033[32;1m${@}\033[0m"
}

function magentaMessage {
    echo -e "\\033[35;1m${@}\033[0m"
}

function cyanMessage {
    echo -e "\\033[36;1m${@}\033[0m"
}

function redMessage {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellowMessage {
	echo -e "\\033[33;1m${@}\033[0m"
}

function errorExit {
    clear
    redMessage ${@}
    exit 1
}

function checkRootUser {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
}

function motd {
    apt-get update
    apt-get install figlet
    clear
    figlet "Nevondo.com Borgmatic Scripts"
    echo -e "\n\n\n"

}

function setupClient {

    if [ -d "/etc/borgmatic" ]; then 
        errorExit "Borgmatic is already installed."
    fi

    magentaMessage "Install Borg with Borgmatic...\n"
    apt-get install borgmatic

    if [ ! -f "/root/.ssh/id_ed25519" ]; then 
        magentaMessage "Generate SSH Key..."
        ssh-keygen -t ed25519 -b 4096
    fi

    magentaMessage "\n What is the Password of the Repo ? \n"
    read password

    magentaMessage "\n Generate /etc/borgmatic/config.yaml..."
    mkdir /etc/borgmatic
    wget_output=$(wget $CONFIG -O "/etc/borgmatic/config.yaml")
    sed -i "s/%HOSTNAME%/$HOSTNAME/g" /etc/borgmatic/config.yaml
    sed -i "s/%PASSWORD%/$password/g" /etc/borgmatic/config.yaml
    
    magentaMessage "Download /etc/systemd/system/borgmatic.service..."
    wget $SERVICE -O "/etc/systemd/system/borgmatic.service"
    magentaMessage "Download /etc/systemd/system/borgmatic.timer..."
    wget $TIMER -O "/etc/systemd/system/borgmatic.timer"
    systemctl daemon-reload
    systemctl enable --now borgmatic.timer
    systemctl start borgmatic.timer

    magentaMessage "Download /etc/borgmatic/mail.sh..."
    wget $MAIL -O "/etc/borgmatic/mail.sh"
    chmod +x "/etc/borgmatic/mail.sh"

    magentaMessage "\n Password for mail dispatch? \n"
    read mailpassword
    sed -i "s/%PASSWORD%/$mailpassword/g" /etc/borgmatic/mail.sh



    greenMessage "########################\n\n"
    greenMessage "Paths:"
    greenMessage "Borgmatic Config File: /etc/borgmatic/config.yaml"
    greenMessage "Public SSH Key: /root/.ssh/id_ed25519.pub"
    greenMessage "Timer File: /etc/systemd/system/borgmatic.timer"
    greenMessage "\n\n########################\n"
    greenMessage "Store the following public key on the backup server:\n"
    cyanMessage "$(cat /root/.ssh/id_ed25519.pub) \n"
    greenMessage "Then create repo:\n"
    cyanMessage "borg init --encryption=repokey-blake2 $HOSTNAME@backup01.nevondo.com:repo"

}


checkRootUser
motd
setupClient