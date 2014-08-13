#!/usr/bin/env bash
#############################################################
## This script reads the PID of a filesystem backup proceess from a text file 
## and try to kill it, if that PID exists. Error is handled by				
## an external script.
## Arguments: $1 = Name of Process status file where PID is stored in first line, first word
##
## Author: Faruque Sarker <writefaruq@gmail.com>
############################################################

SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"

# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh

pid="`cat $FS_STATUS_FILE | awk -F" " {'print $1 '}`"
pid_exists=`kill -0 $pid > /dev/null 2>&1`
if ! $pid_exists; then {
        kill -9 $pid > /dev/null 2>&1
        handle_event "ERROR" "$TIMESTAMP: ERROR backup script killed." # interesting event
        }
fi
