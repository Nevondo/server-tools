#!/bin/bash

apikey=$(cat /opt/codeink/.apikey)
curl -4 -s "https://backend.codeink.de/api/index.php?push_ssh_log&apikey=$apikey&username=$USER&userip=$1"
