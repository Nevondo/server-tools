#!/bin/bash

### Variables ###
TMP="/tmp"
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
    apt-get autoremove -y
}

function InstallPackages {
    apt-get install aptitude molly-guard htop iftop parted tree vim curl screen screenfetch net-tools byobu xinetd grepcidr -y
}

function SetupMonitoring {
    wget $CHECK_MK -O ${TMP}/check-mk-agent.deb
    dpkg -i ${TMP}/check-mk-agent.deb
}

function SetupScreenfetch {
    if ! grep --quiet screenfetch /etc/profile; then
        echo screenfetch >> /etc/profile
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

function SetupLoginNotify {
    mkdir -p /opt/scripts/login-notify/
    rm /opt/scripts/login-notify/login-notify.sh
    rm /etc/ssh/sshrc
    if [ ! -f /opt/scripts/login-notify/config.conf ]; then
        echo -e "\n\n Telegram API Key: "
        read telegram_api_key
        echo -e "\n Telegram Chat ID: "
        read telegram_chat_id
        echo "API_KEY=$telegram_api_key" >> /opt/scripts/login-notify/config.conf
        echo "CHAT_ID=$telegram_chat_id" >> /opt/scripts/login-notify/config.conf
    fi
    echo 'CONN_IP=`echo $SSH_CONNECTION | cut -d " " -f 1`' >> /etc/ssh/sshrc
    echo '/opt/scripts/login-notify/login-notify.sh $CONN_IP' >> /etc/ssh/sshrc
    wget $LOGIN_NOTIFY -O /opt/scripts/login-notify/login-notify.sh
    chmod +x /opt/scripts/login-notify/login-notify.sh
}

function CleanUp {
    rm /etc/motd -f
    rm /etc/update-motd.d/* -R -f
    rm ${TMP}/check-mk-agent.deb
}

function SetRootPassword {
    pw=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
    echo "root:$pw" | chpasswd
    echo "********************************"
    echo "       New root password        "
    echo "$pw"
    echo "********************************"
}

### Main ###
RunChecks
Update
InstallPackages
SetupMonitoring
SetupScreenfetch
SetupBashrc
SetupSsh
SetupQemuAgent
SetupFsTrim
SetupLoginNotify
CleanUp
SetRootPassword
