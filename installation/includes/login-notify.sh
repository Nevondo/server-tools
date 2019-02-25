#!/bin/bash

source /opt/codeink/.apikey

curl -4 -s "https://backend.codeink.de/api/index.php?apikey=$APIKEY&username=$USER&userip=$1&push_ssh_log"
