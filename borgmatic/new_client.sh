#!/bin/bash

BASE_PATH="/srv/borgbackups"

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
    clear
    figlet "Nevondo.com Borgmatic Scripts"
    echo -e "\n\n\n"

}

function newClient {

    magentaMessage "What is the hostname of the server ? \n"
    read hostname
    formatted_hostname=$(echo "$hostname" | sed -r 's/\.//g')

    if [ -d "$BASE_PATH/$formatted_hostname" ]; then
        errorExit "A client with this hostname already exists."
    fi

    mkdir -p $BASE_PATH/$formatted_hostname/
    mkdir -p $BASE_PATH/$formatted_hostname/.ssh
    touch $BASE_PATH/$formatted_hostname/.ssh/authorized_keys
    adduser --disabled-password --home $BASE_PATH/$formatted_hostname $formatted_hostname
    chown -R $formatted_hostname:$formatted_hostname $BASE_PATH/$formatted_hostname

    greenMessage "Username: " $formatted_hostname
    greenMessage "Home-Path: $BASE_PATH/$formatted_hostname"

}




checkRootUser
motd
newClient