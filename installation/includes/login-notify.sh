#!/bin/bash

<<<<<<< HEAD
APIKEY=$(cat /opt/codeink/.apikey)
curl -4 -s "https://backend.codeink.de/api/index.php?push_ssh_log&apikey=$APIKEY&username=$USER&userip=$1"
=======
apikey=$(cat /opt/codeink/.apikey)
curl -4 -s "https://backend.codeink.de/api/index.php?push_ssh_log&apikey=$apikey&username=$USER&userip=$1"
>>>>>>> a6caf3104a7fc6983f59974d561c5b740c12f3af
