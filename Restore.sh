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

echo "Starting Restore $(date)..." >> "$LogFile"

# Function to Restore
restore() {
    echo "Restoring ..." >> $LogFile

    # Restore
	sudo rsync -avhP "$BackupDir" "$SourceDir" 1>> $LogFile

    # Worked well? Unmount.
    if [ $? -eq 0 ]; then
        echo "Restore completed. The removable drive has been unmounted and powered off." >> "$LogFile"
        umount "/dev/disk/by-uuid/$uuid"
        sudo udisksctl power-off -b "/dev/disk/by-uuid/$uuid" >> "$LogFile"
        exit 0
    fi
}

# Call the backup function
restore