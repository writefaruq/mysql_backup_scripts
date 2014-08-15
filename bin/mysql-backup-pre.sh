#!/usr/bin/env bash
#############################################################################################
## Before running the automysqlbackup script this script does some pre-processing
## including mounting file system, checking the disk size, ensuring that the slave is stopped.
##
##
## Author: Faruque Sarker <writefaruq@gmail.com>
#############################################################################################
SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"

# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh

if [[ $CHECK_RUN -ne 1 ]]; then
    # setup at command to schedule the task of killing this backup script if crashed
    echo "$$ STARTED" > $STATUS_FILE
    if [[ $CHECK_SLAVE -ne 1 ]]; then
            at $CLEANUP_TIME  <<< "kill -9 `cat $STATUS_FILE | awk -F" " {'print $1 '}`"
    else
            at $CLEANUP_TIME -f  $HANDLE_CRASH_SCRIPT 2>&1
    fi
fi

# mount file system, ONLY if data is backed up onto a shared file system
if [[  $DO_MOUNT -eq 1 ]]; then 
   source ${SCRIPT_BIN_PATH}/mount_backup_path.sh
fi


# Test writability
temp="$(mktemp ${BACKUP_PATH}/tmp.XXXXXX)"
rm "${temp}" || {
        handle_event "ERROR" "$TIMESTAMP: ERROR File system is not writable $?"
        exit 1
}
if (( $?==0 )); then
        handle_event "INFO" "$TIMESTAMP: INFO File system is writeable."
fi


# Estimate next backup size by reading last backup size from a log file
last_backup_size="$(ls -ltr $BACKUP_PATH/daily/* | tail -1 | awk '{print $5}')" || {
        handle_event "ERROR" "$TIMESTAMP: Can't read the size of last backup $?"
        exit 1
}
if [[ $last_backup_size -gt 0 ]]; then
        last_backup_size=$(( $last_backup_size / 1024 )) # make the size in kb
        handle_event  "INFO" "$TIMESTAMP: INFO Last backup size was $last_backup_size K ."
        next_backup_size=$((  $BACKUP_SIZE_INCREMENT  * $last_backup_size ))
        #handle_event "INFO" "$TIMESTAMP: INFO Next backup allocated size is $next_backup_size K."
fi

# Check free disk space
disk_size=$(df "$BACKUP_PATH" | awk '{ print $3 }' | tail -1)  # TODO: test correctness of awk output
handle_event "INFO"  "$TIMESTAMP: INFO Current disk size $disk_size K"

if [[ $disk_size -gt $next_backup_size ]]; then
        handle_event  "INFO" "$TIMESTAMP: INFO Disk space available."
else {
      	handle_event "ERROR" "$TIMESTAMP: ERROR Not enough disk space."
        exit 1
	}
fi

# End the script if we are running in standalone mode
if [[$CHECK_RUN -eq 1 ]]; then {
    if [[  $DO_MOUNT -eq 1 ]]; then 
        source ${SCRIPT_BIN_PATH}/umount_backup_path.sh
    fi
	handle_event "INFO" "$TIMESTAMP: -------------INFO END of Prebackup tasks---------------"
        exit 0
    }
fi


# Don't proceed if not checking slave
if [[ $CHECK_SLAVE -ne 1 ]]; then
   exit 0
else
  source ${SCRIPT_BIN_PATH}/check_slave.sh
fi

# Write to a metrics file
if [[ $CHECK_RUN -ne 1 ]]; then
    echo "$TIMESTAMP Backup started: $TIMESTAMP" > $METRICS_FILE
fi

handle_event "INFO" "$TIMESTAMP: -------------INFO END of Prebackup tasks---------------"


