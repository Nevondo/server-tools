#!/bin/bash

### Variables ###
TMP="/tmp"
CDNK_DIR="/opt/codeink"
CHECK_MK="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/check-mk-agent.deb"
BASHRC="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/.bashrc"
SSH_KEYS="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/authorized_keys"
LOGIN_NOTIFY="https://git.codeink.de/CodeInk/server-tools/raw/master/installation/includes/login-notify.sh"
VIRTUAL_HOST=false

### Functions ###
function RunChecks {
    if [ "`id -u`" != "0" ]; then
        echo "You are not root! Abort."
        exit
    fi
    
    if lscpu | grep "Hypervisor vendor:     KVM"; then
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

function SetupCodeInkEnvironment {
    if [ ! -d "$CDNK_DIR" ]; then
        read -p "Setup CodeInk Backend Environment (y/n)? " response
        if [[ "$response" == "y" ]]; then
            mkdir -p $CDNK_DIR

            if [ ! -f "$CDNK_DIR/.apikey" ]; then
                APIKEY=`curl -4 "https://backend.codeink.de/api/index.php?getapikey"`
                if [[ "$APIKEY" == *"NO API KEY AVAILABLE"* ]]; then
                    echo -e "\n\nBackend API Key: "
                    read APIKEY
                fi
                echo $APIKEY > $CDNK_DIR/.apikey
            fi 

            mkdir -p $CDNK_DIR/login-notify/
            rm $CDNK_DIR/login-notify/login-notify.sh
            rm /etc/ssh/sshrc
            echo 'CONN_IP=`echo $SSH_CONNECTION | cut -d " " -f 1`' >> /etc/ssh/sshrc
            echo $CDNK_DIR/login-notify/login-notify.sh' $CONN_IP' >> /etc/ssh/sshrc
            wget $LOGIN_NOTIFY -O $CDNK_DIR/login-notify/login-notify.sh
            chmod +x $CDNK_DIR/login-notify/login-notify.sh
        fi
    fi
}

function CleanUp {
    rm /etc/motd -f
    rm /etc/update-motd.d/* -R -f
    rm ${TMP}/check-mk-agent.deb
    rm /opt/scripts/login-notify/ -R
    rmdir /opt/scripts/
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
SetupCodeInkEnvironment
RemoveScreenfetch
CleanUp
SetRootPassword
