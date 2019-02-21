#!/bin/bash

BASE_PATH="/srv/borg/"

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
    apt-get install figlet -y
}

function motd {
    clear
    figlet "CodeInk BorgSetup"
    echo -e "\n\n\n"
}

function newClient {

    echo -e "Where does the host come from (e.g. fal-pve01) ? \n"
    read from
    echo -e "What is the hostname of the server ? \n"
    read hostname

    if [ ! -f "$BASE_PATH/$from" ]; then
        mkdir "$BASE_PATH/$from"
    fi
    
    if [ -f "$BASE_PATH/$from/$hostname" ]; then
        errorExit "A client with this hostname already exists."
    fi

    adduser --disabled-password --home $BASE_PATH/$from/$hostname $hostname
    mkdir $BASE_PATH/$from/$hostname/borgrepo
    chown -R $hostname:$hostname $BASE_PATH/$from/$hostname/borgrepo

}

checkRootUser
install
motd
newClient