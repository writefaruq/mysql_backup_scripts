#!/usr/bin/env bash
#############################################################################################
## This script unmount the backup path 
## 
##
## Author: Faruque Sarker <writefaruq@gmail.com>
#############################################################################################

TIMESTAMP=`date +%Y%m%d%H%M`
BACKUP_PATH="/mnt/backup" 

# unmount filesystem
if [ -d "$BACKUP_PATH" ]; then
    umount $BACKUP_PATH
fi
