#!/bin/bash

### Functions ###

function prepare {
    apt-get install -y dialog curl
}

function createScript {

    key=$( \
		dialog  --title "Add Secret Authkey" \
				--cancel-label "Cancel" \
			    --inputbox "Type in Secret Authkey for Backend (example: 123)" 8 40 \
		3>&1 1>&2 2>&3 3>&- \
	)

    wget -O /etc/profile.d/notify-backend.sh https://git.codeink.de/CodeInk/server-tools/raw/master/login/includes/notify-backend.sh

	sed -i "s/%KEY%/$key/g" /etc/profile.d/notify-backend.sh
}

### Main ###
prepare

if [ ! -f "/etc/profile.d/notify-backend.sh" ]; then
    createScript
else
    echo "/etc/profile.d/notify-backend.sh gibt es bereits!"
fi
