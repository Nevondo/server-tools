#!/bin/sh
apt-get install git -y 
git clone https://git.codeink.de/CodeInk/fail2ban.git
cd fail2ban
chmod +x setup-debian.sh
./setup-debian.sh
cd ..
rm -R fail2ban
