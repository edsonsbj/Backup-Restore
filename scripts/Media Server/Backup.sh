#!/bin/bash

CONFIG="$(dirname "${BASH_SOURCE[0]}")/BackupRestore.conf"
. $CONFIG

## ---------------------------- TESTS ---------------------------- #

# Check if the script is being executed by root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script needs to be executed as root or with sudo."
   exit 1
fi

# Check if the removable drive is connected and mounted correctly
if lsblk -no uuid /dev/sd* | grep -q "$uuid"; then
    echo "The drive is connected and mounted."
    sudo mount -U $uuid $BackupDir
else
    echo "The drive is not connected or mounted."
    exit 1
fi

# Check for write and read permissions
if [ ! -w "$BackupDir" ]; then
  echo "No write permissions in $BackupDir"
  exit 1
fi

echo "Changing to the root directory..."
cd /
if [ $? -eq 0 ]; then
    echo "Changed to the root directory successfully."
else
    echo "Failed to change to the root directory. Restoration failed."
    exit 1
fi

clear

## -------------------------- MAIN SCRIPT -------------------------- #

echo "Starting Backup $(date)..." >> "$LogFile"

# Function to backup
backup() {
    echo "Backing up Media Server settings..." >> "$LogFile"

    # Stop Media Server
    systemctl stop "$MediaserverService"

    # Backup
    sudo rsync -avhP --delete --exclude={'*/Cache','*/cache','*/Crash Reports','*/Diagnostics','*/Logs','*/logs','*/transcoding-temp'} "$MediaserverConf" "$BackupDir/Mediaserver" 1>> $LogFile

    # Start Media Server
    systemctl start "$MediaserverService"
    
    # Worked well? Unmount.
    if [ $? -eq 0 ]; then
        echo "Backup completed. The removable drive has been unmounted and powered off." >> "$LogFile"
        umount "/dev/disk/by-uuid/$uuid"
        sudo udisksctl power-off -b "/dev/disk/by-uuid/$uuid" >> "$LogFile"
        exit 0
    fi
}

# Call the backup function
backup
