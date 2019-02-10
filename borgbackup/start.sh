#!/bin/bash

BACKUP_SH="https://git.codeink.de/CodeInk/server-tools/raw/master/borgbackup/includes/backup.sh"
BACKUP_SH_PATH="/opt/borgbackup/backup.sh"

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
    $clear
    redMessage ${@}
    exit 1
}

function checkRootUser {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
}

function install {
    apt-get update
    apt-get install figlet borgbackup -y
}

function motd {
    clear
    figlet "CodeInk BorgSetup"
    echo -e "\n\n\n"
}


function readAuth {
    echo -e "Remote Host:\n"
    read host
    echo -e "\nRemote User:\n"
    read user
    echo -e "\nRepository Compression:\n"
    read compression
    echo -e "\nRepository Path:\n"
    read repo_path
    echo -e "\nRepository Passphrase:\n"
    read -s password
}

function genSSHKey {
     if [ ! -f ~/.ssh/id_rsa.pub ]; then
        redMessage "SSH Key not found!"
        ssh-keygen -t rsa -b 4096
    fi
}

function showSSHKey {
    yellowMessage "Add the public ssh key on remote host.\n"
    echo -e "mkdir -m 0700 ~/.ssh \nnano .ssh/authorized_keys //Hier den Key einfügen \nchmod 600 .ssh/authorized_keys \n"
    cat ~/.ssh/id_rsa.pub 
    read -p"Finished (j)? " response_finished
}

function setupScript {
    mkdir -p /opt/borgbackup

    wget $BACKUP_SH -O $BACKUP_SH_PATH
    
    sed -i "s/%USER%/$user/g" $BACKUP_SH_PATH
    sed -i "s/%HOST%/$host/g" $BACKUP_SH_PATH
    sed -i "s/%REPO_PATH%/$repo_path/g" $BACKUP_SH_PATH
    sed -i "s/%PASSPHRASE%/$password/g" $BACKUP_SH_PATH
    sed -i "s/%COMPRESSION%/$compression/g" $BACKUP_SH_PATH

}

function initRepo {
    export BORG_REPO=ssh://$user@$host:22/$repo_path
    borg init 
}

install
motd
checkRootUser
readAuth
genSSHKey
showSSHKey
setupScript
initRepo





#wget  https://git.codeink.de/CodeInk/server-tools/raw/master/borgbackup/start.sh; chmod 777 start.sh ; ./start.sh ; rm start.sh
