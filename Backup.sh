#!/bin/bash

CONFIG="$(dirname "${BASH_SOURCE[0]}")/BackupRestore.conf"
. $CONFIG

## ---------------------------------- TESTS ------------------------------ #

# Check if the script is being executed by root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "########## This script needs to be executed as root or with sudo. ##########" 
   exit 1
fi

# Check if the removable drive is connected and mounted correctly
if [[ $(lsblk -no uuid /dev/sd*) == *"$uuid"* ]]; then
    echo "########## The drive is connected and mounted. ##########"
    sudo mount -U $uuid $BackupDir
else
    echo "########## The drive is not connected or mounted. ##########"
    exit 1
fi

# Are there write and read permissions?
[ ! -w "$BackupDir" ] && {
  echo "########## No write permissions ##########" >> $LogFile
  exit 1
}

echo "Changing to the root directory..."
cd /
echo "pwd is $(pwd)"
echo "backup file location db is " '/'

if [ $? -eq 0 ]; then
    echo "Done"
else
    echo "failed to change to root directory. Restoration failed"
    exit 1
fi

clear

## ------------------------------------------------------------------------ #

   echo "########## Starting Backup $( date ). ##########" >> $LogFile

# -------------------------------FUNCTIONS----------------------------------------- #

# Function to backup 
backup() {
    echo "############### Backing up ... ###############" >> $LogFile

    # Backup
	sudo rsync -avhP --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} "$SourceDir" "$BackupDir" 1>> $LogFile

  # Worked well? Unmount.
  [ "$?" = "0" ] && {
    echo "############## Backup completed. The removable drive has been unmounted and powered off. ###########" >> $LogFile
 	eval umount /dev/disk/by-uuid/$uuid
	eval sudo udisksctl power-off -b /dev/disk/by-uuid/$uuid >>$LogFile
    exit 0
  }
}