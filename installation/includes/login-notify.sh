#!/bin/bash

source /opt/scripts/login-notify/config.conf

TRUSTED_NETWORKS="192.168.76.0/24 10.12.0.0/24 10.15.0.0/24"
IP_CHECK=$1

grepcidr "$TRUSTED_NETWORKS" <(echo "$IP_CHECK") >/dev/null || \
    curl -X POST "https://api.telegram.org/bot$API_KEY/sendMessage?chat_id=$CHAT_ID&text=Login auf $(hostname) am $(date +%Y-%m-%d) um $(date +%H:%M) Benutzer: $USER IP: $IP_CHECK" 2> /dev/null > /dev/null