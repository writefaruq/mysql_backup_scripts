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

# check MySQL slave
slave_status=$(mysql -h `hostname -f` -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW GLOBAL STATUS like 'slave_running' " 2>&1 | grep Slave_running | awk -F" " {'print $2 '})
handle_event "INFO"  "$TIMESTAMP: INFO MySQL Slave status: $slave_status" 
if [[ -n  "$slave_status" && "$slave_status"  == 'OFF' ]]; then 
    handle_event "INFO"  "$TIMESTAMP: INFO Slave is found stopped. Starting now..." 
        start_slave=$(mysql -h `hostname -f` -u $MYSQL_USER -p$MYSQL_PASS -e "START SLAVE SQL_THREAD" 2>&1)
    slave_status=$(mysql -h `hostname -f` -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW GLOBAL STATUS like 'slave_running' " 2>&1 | grep Slave_running | awk -F" " {'print $2 '})
    if [[ -n  "$slave_status" && "$slave_status"   == 'ON' ]]; then 
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
