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

# -------------------------------FUNCTIONS----------------------------------------- #

# Function to backup Nextcloud settings
nextcloud_settings() {
    echo "========== Backing up Nextcloud settings $( date )... =========="
    echo ""
   	
    # Enabling Maintenance Mode
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on

	# Stop Web Server
	systemctl stop $webserverServiceName

    # Backup
	sudo rsync -avhP --delete --exclude '*/data/' "$NextcloudConfig" "$BackupDir/Nextcloud"

	# Export the database.
	mysqldump --quick -n --host=localhost $NextcloudDatabase --user=$DBUser --password=$DBPassword > "$BackupDir/Nextcloud/nextclouddb_.sql"

	# Start Web Server
	systemctl start $webserverServiceName

	# Disabling Nextcloud Maintenance Mode
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off
}

# Function to backup Nextcloud DATA folder
nextcloud_data() {
    echo "========== Backing up Nextcloud DATA folder $( date )...=========="
    echo ""

	# Enabling Maintenance Mode

	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on

    # Backup
	sudo rsync -avhP --delete --exclude '*/files_trashbin/' "$NextcloudDataDir" "$BackupDir/Nextcloud_datadir"

	# Disabling Nextcloud Maintenance Mode
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off
}

# Function to perform a complete Nextcloud backup
nextcloud_complete() {
    nextcloud_settings
    nextcloud_data
}

# Check if an option was passed as an argument
if [[ ! -z $1 ]]; then
    # Execute the corresponding Backup option
    case $1 in
        1)
            nextcloud_complete
            ;;
        2)
            nextcloud_settings
            ;;
        3)
            nextcloud_data
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac

else
    # Display the menu to choose the Backup option
    echo "Choose a Backup option:"
    echo "1. Backup Nextcloud configurations, database, and data folder."
    echo "2. Backup Nextcloud configurations and database."
    echo "3. Backup only the Nextcloud data folder. Useful if the folder is stored elsewhere."
    echo "4. To go out."

    # Read the option entered by the user
    read option

    # Execute the corresponding Backup option
    case $option in
        1)
            nextcloud_complete
            ;;
        2)
            nextcloud_settings
            ;;
        3)
            nextcloud_data
            ;;
        4)
            echo "Leaving the script."
            exit 0
            ;;            
        *)
            echo "Invalid option!"
            ;;
    esac
fi

# Worked well? Unmount.
if [ "$?" = "0" ]; then
    echo ""
    echo "========== Backup completed. The removable drive has been unmounted and powered off. =========="
    umount "/dev/disk/by-uuid/$uuid"
    sudo udisksctl power-off -b "/dev/disk/by-uuid/$uuid"
    exit 0
fi
