#!/usr/bin/env bash
#############################################################################################
## This script unmount the backup path 
## 
##
## Author: Faruque Sarker <writefaruq@gmail.com>
#############################################################################################
SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"

# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh 

# Unmount filesystem, ONLY if we mounted file system before
if [ -d "$BACKUP_PATH" ]; then
	handle_event "INFO" "$TIMESTAMP: INFO Unmounting file system ."
	umount $BACKUP_PATH
   if (( $?==0 )); then
           handle_event "INFO" "$TIMESTAMP: INFO File system unmounted sucessfully."
   else {
           handle_event "ERROR" "$TIMESTAMP: ERROR File system unmount failed $?."
           exit 1
   }
   fi
fi
