#!/usr/bin/env bash
##########################################################################
## This script processes events such as write to log file or send email
##
## Author: Faruque Sarker <writefaruq@gmail.com>
##########################################################################
#MAILTO='user@domain.com' #use a space separated list of email addresses e.g. "user1@localhost  user2@localhost"
#MAILFROM='user@domain.com'

handle_event () {
	# $1 = Severity level: ERROR, WARN, INFO
	# $2 = Error msg
	if [[ $1 = 'ERROR' ]]; then
	    echo $2 | mail -s "`hostname -f`:Backup $2 @ $TIMESTAMP" -r $MAILFROM $MAILTO
	    echo $2 1>&2
	else
    	     echo $2 >&1
	fi
}

email_log () {
	cat $1 | mail -s "`hostname -f`: Backup report @ $TIMESTAMP" -r $MAILFROM $MAILTO 
	echo "$TIMESTAMP: Email sent with logfile $1" >&1
}
