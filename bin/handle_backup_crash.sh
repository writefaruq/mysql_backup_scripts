#!/bin/bash
##########################################################################
## This script kill a crashed or unfinished backup script
##
## Author: Faruque Sarker <writefaruq@gmail.com>
##########################################################################
SCRIPT_BIN_PATH="/db01/mysql01/backups/bin"
SCRIPT_CONFIG_PATH="/db01/mysql01/backups/config"

# load the config and lib
source ${SCRIPT_CONFIG_PATH}/backup_tasks.conf
source ${SCRIPT_BIN_PATH}/backup_tasks_lib.sh

# kill the backup task
pid="`cat $STATUS_FILE | awk -F" " {'print $1 '}`"
handle_event "INFO" "Killing backup process: $pid"
pid_exists=`kill -0 $pid > /dev/null 2>&1`
if ! $pid_exists; then {
		kill -9 $pid > /dev/null 2>&1
		handle_event "ERROR" "$TIMESTAMP: ERROR backup script killed." # interested event
	}
fi
# Un-comment if the job outout email is desireable
#else
#	handle_event "INFO" "$TIMESTAMP: INFO  backup script $pid not running"
#fi 



# ensure slave is running
mysql -u $MYSQL_USER -p$MYSQL_PASS -e "START SLAVE" 2>&1
slave_status=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW GLOBAL STATUS like 'slave_running' " 2>&1 | grep Slave_running | awk -F" " {'print $2 '})

#echo "$TIMESTAMP: MySQL Slave status: $slave_status" 

if [ $slave_status  == 'ON' ]; then
    handle_event "INFO" "$TIMESTAMP: INFO Slave has started."
else {
	handle_event "ERROR" "$TIMESTAMP: ERROR Slave failed to start."
 	exit 1
    }
fi
