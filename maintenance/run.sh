#!/bin/bash

### Variables ###
TMP="/tmp"
CHECK_MK="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/check-mk-agent.deb"
BASHRC="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/.bashrc"
SSH_KEYS="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/authorized_keys"
LOGIN_NOTIFY="https://git.codeink.de/CodeInk/server-tools/raw/master/maintenance/includes/login-notify.sh"
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
    apt-get install aptitude molly-guard htop iftop parted tree vim curl screen neofetch net-tools byobu xinetd -y
}

function SetupMonitoring {
    wget $CHECK_MK -O ${TMP}/check-mk-agent.deb
    dpkg -i ${TMP}/check-mk-agent.deb
}

function RemoveScreenfetch {
    if grep --quiet screenfetch /etc/profile; then
        sed -i "s|screenfetch||g" /etc/profile
    fi
    apt-get purge screenfetch -y
}

function SetupNeofetch {
    if ! grep --quiet neofetch /etc/profile; then
        echo neofetch >> /etc/profile
    fi
}

function SetupBashrc {
    rm .bashrc
    wget $BASHRC -O .bashrc
    source .bashrc
}

function SetupSsh {
    mkdir /root/.ssh/
    wget $SSH_KEYS -O /root/.ssh/authorized_keys
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
RemoveScreenfetch
CleanUp
