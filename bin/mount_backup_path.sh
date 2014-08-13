#!/usr/bin/env bash
###################################################################################
## If the backup files are stored on a SMB/CIFS share, this script mount that share
##
## Author: Faruque Sarker <writefaruq@gmail.com>
####################################################################################
SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"
# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh

# mount file system
MOUNT_CREDENTIALS='/db01/mysql01/backups/config/cifs.pwd'
MOUNT_SRC_PATH='//slmsidhssanmt01/MySQL_Backups'


# mount file system
mkdir -p "$BACKUP_PATH"
mount.cifs -o credintials="$MOUNT_CREDENTIALS" "$MOUNT_SRC_PATH" "$BACKUP_PATH" || { 
	handle_event  "ERROR" "$TIMESTAMP: ERROR File system mount failed." 
	exit 1 
}

mkdir -p "$BACKUP_PATH"/`hostname -s`/mysql || { 
	handle_event "ERROR" "$TIMESTAMP: ERROR Can't create backup path $BACKUP_PATH/mysql."
 	exit 1 
}

#mkdir -p "$BACKUP_PATH"/`hostname -s`/filesystem_backup || {
#        handle_event "ERROR" "$TIMESTAMP: ERROR Can't create backup path $BACKUP_PATH/filesystem_backup."
#        exit 1
#}


if (( $?==0 )); then
	handle_event "INFO" "$TIMESTAMP: INFO File system is mounted."
fi
