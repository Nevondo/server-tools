#!/bin/bash

exec > >(tee -i ${LOG})
exec 2>&1
echo "###### Starting on $(date) ######"

if [ -f %BACKUP_SH_DIR%precmd.sh ]; then
    source %BACKUP_SH_DIR%precmd.sh
fi

export BORG_REPO=ssh://%USER%@%HOST%:22%REPO_PATH%
export BORG_PASSPHRASE='%PASSPHRASE%'
export BORG_PASSCOMMAND='pass show backup'

echo "###### Starting backup ######"

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression %COMPRESSION%     \
    --exclude '/dev/*'              \
    --exclude '/proc/*'             \
    --exclude '/sys/*'              \
    --exclude '/tmp/*'              \
    --exclude '/run/*'              \
    --exclude '/mnt/*'              \
    --exclude '/media/*'            \
    --exclude '/srv/*'              \
    --exclude '/lost+found/*'       \
    --exclude '/home/*/.cache/*'    \
    --exclude '/var/cache/*'        \
    --exclude '/var/tmp/*'          \
                                    \
    ::'{hostname}-{now}'            \
    /                               \

backup_exit=$?

echo "###### Pruning repository ######"


borg prune                          \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-daily    30              \
    --keep-weekly   12              \
    --keep-monthly  15              \

echo "###### Finished on $(date) ######"

prune_exit=$?

global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    echo "###########################################"
    echo "Backup and/or Prune finished with a warning"
    echo "###########################################"
fi

if [ ${global_exit} -gt 1 ];
then
    echo "###########################################"
    echo "Backup and/or Prune finished with an error"
    echo "###########################################"
fi

exit ${global_exit}

echo $LOG > last.log