#!/usr/bin/env bash
#############################################################################################
## This script checks the MySQL salve and stops prior to take the backup
## 
##
## Author: Faruque Sarker <writefaruq@gmail.com>
#############################################################################################
SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"

# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh


## Check and stop MySQL slave
# Check if the replication link is broken
handle_event "INFO" "$TIMESTAMP: INFO Checking MySQL Master-Slave link."
seconds_behind_master=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW SLAVE STATUS\G" 2>&1 | grep "Seconds_Behind_Master" | awk -F": " {' print $2 '})
if [ "$seconds_behind_master" == "NULL" ]; then {
    handle_event "ERROR" "$TIMESTAMP: ERROR Slave replication broken." 
    if ! $IGNORE_NON_FATAL; then
    	exit 1 # 
    fi
    }
else
    if [ "$seconds_behind_master" -gt "$SLAVE_ACCEPTABLE_LAG" ]; then
	    handle_event "INFO" "$TIMESTAMP: INFO Slave replication is $seconds_behind_master seconds behind." 
    else
	    handle_event "INFO" "$TIMESTAMP: INFO Slave replication is up-to-date." 
	    mysql -u $MYSQL_USER -p$MYSQL_PASS -e "STOP SLAVE" 2>&1 || {
		handle_event "ERROR" "$TIMESTAMP: ERROR Slave stop failed" 
		exit 1
	    }
	    slave_status=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW GLOBAL STATUS like 'slave_running' " 2>&1 | grep Slave_running | awk -F" " {'print $2 '})
	    if [ $slave_status  == 'OFF' ]; then 
		handle_event "INFO" "$TIMESTAMP: INFO Slave has stopped."
            else { 
            	handle_event "ERROR" "$TIMESTAMP: ERROR Slave failed to stop." 
	    	exit 1
	    }
	    fi	
    fi # end seconds_behind_master check
fi # end of NULL value check
