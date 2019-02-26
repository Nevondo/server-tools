#!/bin/bash

APIKEY=$(cat /opt/codeink/.apikey)
curl -4 -s "https://backend.codeink.de/api/index.php?push_ssh_log&apikey=$APIKEY&username=$USER&userip=$1" >> /dev/null
