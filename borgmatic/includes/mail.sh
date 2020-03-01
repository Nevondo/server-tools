MAILFILE="/tmp/borgmaticmail.txt"
MAILSERVER="smtps://mx01.nevondo.com:465"
FROM="$(hostname)@nevondo.com"
TO="hostmaster@nevondo.com"
ACCESS='server@nevondo.com:%PASSWORD%'

if [ -f $MAILFILE ]; then
    rm $MAILFILE
fi

if [ "$1" == "failed" ]; then
    STATUS="failed"
elif [ "$1" == "successful" ]; then
    STATUS="successful"
else 
    exit 1
fi

echo -e "From: Borgmatic <$FROM> \nTo: Hostmaster <$TO> \nSubject: $(hostname) Backup $STATUS \nDate: $(date -R)\n\n $(tail -n 250 /var/log/syslog)" >> $MAILFILE
curl --url $MAILSERVER --ssl-reqd --mail-from $FROM --mail-rcpt $TO --upload-file $MAILFILE --user $ACCESS