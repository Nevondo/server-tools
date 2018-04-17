#!/bin/bash

### Functions ###

function which {

    if [ -d "/etc/profile.d/notify-backend.sh" ]; then
        echo 1
    else
        echo 0
    fi

}

function createScript {

    key=$( \
		dialog  --title "Add Secret Authkey" \
				--cancel-label "Cancel" \
			    --inputbox "Type in Secret Authkey for Backend (example: 123)" 8 40 \
		3>&1 1>&2 2>&3 3>&- \
	)

    wget https://git.codeink.de/CodeInk/server-scripts/raw/master/login/includes/notify-backend.sh

	sed -i "s/%KEY%/$key/g" /etc/profile.d/notify-backend.sh
}

### Main ###

if [ ! which ]; then
    createScript
else
    echo "etc/profile.d/notify-backend.sh gibt es bereits!"
fi
