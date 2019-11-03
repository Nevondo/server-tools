#!/bin/bash

### Variables ###
TMP="/tmp"
CHECK_MK="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/check-mk-agent.deb"
BASHRC="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/.bashrc"
SSH_KEYS="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/authorized_keys"
VIRTUAL_HOST=false

### Functions ###
function RunChecks {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
    
    # Debian 9
    if lscpu | grep "Hypervisor vendor:     KVM"; then
        VIRTUAL_HOST=true
    fi
    
    # Debian 10
    if lscpu | grep "Hypervisor vendor:   KVM"; then
        VIRTUAL_HOST=true
    fi
}

function Update {
    apt-get update
    apt-get dist-upgrade -y
}

function InstallPackages {
    apt-get install molly-guard htop iftop parted tree vim curl screen neofetch net-tools byobu xinetd -y
}

function SetupMonitoring {
    wget_output=$(wget $CHECK_MK -O "${TMP}/check-mk-agent.deb")
    if [ ! $? -ne 0 ]; then
        dpkg -i ${TMP}/check-mk-agent.deb
    fi
}

function SetupNeofetch {
    if ! grep --quiet neofetch /etc/profile; then
        echo neofetch >> /etc/profile
    fi
}

function SetupBashrc {
    wget_output=$(wget $BASHRC -O "${TMP}/bashrc")
    if [ ! $? -ne 0 ]; then
        rm /root/.bashrc
        mv ${TMP}/bashrc /root/.bashrc
    fi
}

function SetupSsh {
    mkdir /root/.ssh/
    wget_output=$(wget $SSH_KEYS -O "${TMP}/authorized_keys")
    if [ ! $? -ne 0 ]; then
        mv ${TMP}/authorized_keys /root/.ssh/authorized_keys
    fi
    sed -i "/^[#?]*PasswordAuthentication[[:space:]]/c\PasswordAuthentication no" /etc/ssh/sshd_config
    systemctl restart ssh
}

function SetupQemuAgent {
    if "$VIRTUAL_HOST" ; then
        apt-get install qemu-guest-agent -y
    fi
}

function SetupFsTrim {
    if "$VIRTUAL_HOST" ; then
        rm /etc/cron.weekly/trim
        echo "#!/bin/bash" >> /etc/cron.weekly/trim
        echo "/sbin/fstrim --all || true" >> /etc/cron.weekly/trim
        chmod +x /etc/cron.weekly/trim
    fi
}


function CleanUp {
    rm /etc/motd -f
    rm /etc/update-motd.d/* -R -f
    rm ${TMP}/check-mk-agent.deb
    apt-get autoremove -y
}

function SetRootPassword {
    read -p "New root password (y/n)? " response
    if [[ "$response" == "y" ]]; then
        pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
        echo "root:$pw" | chpasswd
        echo "********************************"
        echo "       New root password        "
        echo "$pw"
        echo "********************************"
    fi
}

### Main ###
RunChecks
Update
InstallPackages
SetupMonitoring
SetupNeofetch
SetupBashrc
SetupSsh
SetupQemuAgent
SetupFsTrim
CleanUp
SetRootPassword
