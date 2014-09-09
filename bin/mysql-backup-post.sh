#!/usr/bin/env bash
###################################################################################
## After running the automysqlbackup script this script does some post processing 
## including unmounting file system, write backup mertics to a log file and 
## ensuring that the slave is running.
##
## Author: Faruque Sarker <writefaruq@gmail.com>
###################################################################################
SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"

# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh

last_backup_size=${ESTIMATED_BACKUP_SIZE}	

# Get backup size
if [ -d "$DAILY_BACKUP_FILE_PATH" ]; then
    last_backup_size="$(ls -ltr $DAILY_BACKUP_FILE_PATH | tail -1 | awk '{print $5}')" || { 
    handle_event "ERROR" "$TIMESTAMP: Can't read the size of last backup $?"
    exit 1
    }
fi

# unmount filesystem
if [[  $DO_MOUNT -eq 1 ]]; then 
    source ${SCRIPT_BIN_PATH}/umount_backup_path.sh
fi

if [[ $CHECK_SLAVE -eq 1 ]]; then
    source ${SCRIPT_BIN_PATH}/check_slave_start.sh
fi # end of check slave

# Write to a metrics file
end_time=$(($(date +%s%N)/1000000))
echo  "$TIMESTAMP Backup finished: $end_time" >> $METRICS_FILE

# read start time and calculate the duration
start_time="`cat $METRICS_FILE | head -1 | awk -F": " {' print $2 '}`"
handle_event "INFO" "Start time : $start_time ---- End time: $end_time"
diff=$(( $end_time - $start_time )) 
echo  "$TIMESTAMP Duration: $diff nanoseconds" >> $METRICS_FILE
start_time=$(( $start_time / 1000000 )) # convert to sec
end_time=$(( $end_time / 1000000 ))

# Notice TSM backup gurad time
TODAY=`date +%Y%m%d`
tsm_start_time=`date  --date="$TODAY $TSM_BACKUP_TIME" "+%s"`
handle_event "INFO" "$TIMESTAMP: TSM backup start time: `date -d @$tsm_start_time`"
guard_time=$(( $tsm_start_time - $end_time ))
echo  "$TIMESTAMP Guard time: $guard_time" >> $METRICS_FILE
if [[ $guard_time -le 0 ]]; then {
    handle_event "ERROR"  "$TIMESTAMP: ERROR Backup task ran after TSM Backup started"
    exit 1
    }
fi

if [[ $guard_time -le $GUARD_TIME_THRESHOLD ]]; then
    handle_event "INFO"  "$TIMESTAMP: WARNING Backup task ran within Guard time threshold"
else
    handle_event "INFO"  "$TIMESTAMP: INFO Backup task ran before the Guard time threshold"
fi

# Write Size/ Speed etc.
echo  "$TIMESTAMP Backup size: $last_backup_size" >> $METRICS_FILE

speed=0
if [[ $diff -gt 0 ]]; then
	speed=$(( $last_backup_size / $diff ))
fi

echo  "$TIMESTAMP Backup speed: $speed Kb/ns" >> $METRICS_FILE

handle_event "INFO"  "$TIMESTAMP  -----------END of Post MySQL backup tasks-------------" 
