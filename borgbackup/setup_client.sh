#!/bin/bash

BACKUP_SH="https://git.nevondo.com/Nevondo/server-tools/raw/master/borgbackup/includes/backup.sh"
BACKUP_SH_DIR="/opt/borgbackup/"
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
    echo -e "\nMail From:\n"
    read mail_from
    echo -e "\nMail To:\n"
    read mail_to
    echo -e "\nMail User:\n"
    read mail_user
    echo -e "\nMail Password:\n"
    read -s mail_password
    echo -e "\nMail Server:\n"
    read mail_server
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
    mkdir -p $BACKUP_SH_DIR

    wget $BACKUP_SH -O $BACKUP_SH_PATH
    
    sed -i "s/%USER%/$user/g" $BACKUP_SH_PATH
    sed -i "s/%HOST%/$host/g" $BACKUP_SH_PATH
    sed -i 's|%REPO_PATH%|'$repo_path'|g' $BACKUP_SH_PATH
    sed -i "s/%PASSPHRASE%/$password/g" $BACKUP_SH_PATH
    sed -i "s/%COMPRESSION%/$compression/g" $BACKUP_SH_PATH

    sed -i "s|%BACKUP_SH_DIR%|$BACKUP_SH_DIR|g" $BACKUP_SH_PATH

    sed -i "s|%MAILFROM%|$mail_from|g" $BACKUP_SH_PATH
    sed -i "s|%MAILTO%|$mail_to|g" $BACKUP_SH_PATH
    sed -i "s|%MAILUSER%|$mail_user|g" $BACKUP_SH_PATH
    sed -i "s|%MAILPASSWORD%|$mail_password|g" $BACKUP_SH_PATH
    sed -i "s|%MAILSERVER%|$mail_server|g" $BACKUP_SH_PATH


    chmod 777 $BACKUP_SH_PATH

}

function initRepo {
    yellowMessage "Repository Passphrase:"
    export BORG_REPO=ssh://$user@$host:22$repo_path
    borg init --encryption=repokey
}

function preCmd {
    yellowMessage "Are there commands or scripts that should be executed before the backup? \n"
    read -p"(y/n)?" response_pre
    if [ "$response_pre" == "y" ]; then
        nano $BACKUP_SH_DIR/precmd.sh
    fi
}

function addCronTab {
    echo "0 3	* * *	root	"$BACKUP_SH_PATH"  > /dev/null 2>&1 " > /etc/cron.d/borgbackup
    yellowMessage "Do you want to change the cronjob? \n"
    read -p"(y/n)?" response_crontab
    if [ "$response_crontab" == "y" ]; then
        nano /etc/cron.d/borgbackup
    fi
}

install
motd
checkRootUser
readAuth
genSSHKey
motd
showSSHKey
setupScript
initRepo
preCmd
addCronTab
