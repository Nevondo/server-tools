#!/bin/bash

### Functions ###

function GetSystemInfos {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    fi
}

function CheckRootUser {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
}

function Install {
    apt update
    apt upgrade -y
    apt install aptitude molly-guard htop iftop parted tree vim curl screen screenfetch byobu -y
    echo screenfetch >> /etc/profile
    rm .bashrc
    wget https://git.codeink.de/CodeInk/server-scripts/raw/master/installation/includes/.bashrc -O .bashrc
    rm /etc/motd -f
    rm /etc/update-motd.d/* -R -f
}

function CheckInstallation {
    if [ -f .installed ]; then
        echo "Already installed! Abort."
        exit
    fi
    echo "true" > .installed
}

### Main ###

OS=$(uname -s)
VER=$(uname -r)

CheckRootUser
GetSystemInfos
# Todo AAP: Check Version
CheckInstallation
Install
