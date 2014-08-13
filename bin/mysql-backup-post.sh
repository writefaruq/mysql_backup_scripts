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

# Get backup size
last_backup_size="$(ls -ltr $BACKUP_PATH/`hostname -s`/mysql/daily/redcap | tail -1 | awk '{print $5}')"


# unmount filesystem
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

if [[ $CHECK_SLAVE -eq 1 ]]; then
    # check MySQL slave
    slave_status=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW GLOBAL STATUS like 'slave_running' " 2>&1 | grep Slave_running | awk -F" " {'print $2 '})
    handle_event "INFO"  "$TIMESTAMP: INFO MySQL Slave status: $slave_status" 
    if [ "$slave_status"  == OFF ]; then 
	    handle_event "INFO"  "$TIMESTAMP: INFO Slave is found stopped. Starting now..." 
            start_slave=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "START SLAVE" 2>&1)
	    slave_status=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW GLOBAL STATUS like 'slave_running' " 2>&1 | grep Slave_running | awk -F" " {'print $2 '})
	    if [ $slave_status  == 'ON' ]; then 
		    handle_event "INFO"  "$TIMESTAMP: INFO Slave has been started." 
            else {
            	handle_event "ERROR"  "$TIMESTAMP: ERROR Slave is not started. status is $slave_status." 
		exit 1
	    }
	    fi	
    else
        handle_event "INFO"  "$TIMESTAMP: INFO Slave is found running."
        handle_event "INFO"  "$TIMESTAMP: INFO Exiting now." 
    fi # end of slave status check
fi # end of check slave

# Write to a metrics file
end_time=$(date +"%s")
echo  "$TIMESTAMP Backup finished: $end_time" >> $METRICS_FILE

# read start time and calculate the duration
start_time="`cat $METRICS_FILE | head -1 | awk -F": " {' print $2 '}`"
diff=$(( $end_time - $start_time ))
echo  "$TIMESTAMP Duration: $(($diff / 60)) minutes and $(($diff % 60)) seconds" >> $METRICS_FILE

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

echo  "$TIMESTAMP Backup speed: $speed Kb/s" >> $METRICS_FILE

handle_event "INFO"  "$TIMESTAMP  -----------END of Post MySQL backup tasks-------------\n" 

