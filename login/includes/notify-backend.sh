KEY=%KEY%
HOST=`hostname -f`
USERNAME=`who -m | awk '{print $1}'`
USERIP=`who -m | awk '{print $5}' | sed s/"("// | sed s/")."// | sed s/")"// | sed s/")."//`


curl -k https://backend.codeink.de/api/login.php?key=$KEY&host=$HOST&username=$USERNAME&userip=$USERIP