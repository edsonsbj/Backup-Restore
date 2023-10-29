#!/bin/bash

CONFIG="$(dirname "${BASH_SOURCE[0]}")/BackupRestore.conf"
. $CONFIG

# Create a log file to record command outputs
touch "$LogFile"
exec > >(tee -a "$LogFile")
exec 2>&1

## ---------------------------------- TESTS ------------------------------ #

# Check if the script is being executed by root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "========== This script needs to be executed as root or with sudo. ==========" 
   exit 1
fi

device=$(blkid -U "$uuid")

if [ -z "$device" ]; then
  echo "========== The unit with UUID $uuid Is not connected. Leaving the script.=========="
  exit 1
fi

echo "========== The unit with UUID $uuid is connected and corresponds to the device $device. =========="

# Check that the unit is assembled
if grep -qs "$BackupDisk" /proc/mounts; then
  echo "========== The unit is assembled ==========."
else
  echo "========== The unit is not assembled. Trying to assemble...=========="

  # Try to assemble the unit
  if mount "$device" "$BackupDisk"; then
    echo "========== The unit was successfully assembled.=========="
  else
    echo "========== Failure when setting up the unit. Leaving the script.=========="
    exit 1
  fi
fi

# Are there write and read permissions?
if [ ! -w "$BackupDisk" ]; then
    echo "========== No write permissions =========="
    exit 1
fi

## -------------------------- MAIN SCRIPT -------------------------- #

echo "Starting Restore $(date)..." >> "$LogFile"

# Function to Restore 
Restore() {
    echo "Backing up Media Server settings..." >> "$LogFile"

    # Remove the current directory from Media Derver
    mv "$MediaserverConf" "$MediaserverConf.bk"

    # Stop Media Server
    sudo systemctl stop $MediaserverService

    # Restore
    sudo rsync -avhP "$BackupDir/Mediaserver" "$MediaserverConf" 1>> $LogFile

    # Start Media Server
    sudo systemctl start $MediaserverService

    # Restore permissions
    chmod -R 755 $MediaserverConf
    chown -R $MediaserverUser:$MediaserverUser $MediaserverConf

    # Add the Media Server User to the www-data group to access Nextcloud folders
    sudo adduser $MediaserverUser www-data

    # Worked well? Unmount.
    if [ $? -eq 0 ]; then
        echo ""
        echo "Restore completed. The removable drive has been unmounted and powered off." >> "$LogFile"
        umount "/dev/disk/by-uuid/$uuid"
        sudo udisksctl power-off -b "/dev/disk/by-uuid/$uuid" >> "$LogFile"
        exit 0
    fi
}

# Call the Restore function
Restore
