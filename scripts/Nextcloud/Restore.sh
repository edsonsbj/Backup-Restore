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
   echo "########## This script needs to be executed as root or with sudo. ##########" 
   exit 1
fi

# Check if the removable drive is connected and mounted correctly
if [[ $(lsblk -no uuid /dev/sd*) == *"$uuid"* ]]; then
    echo "########## The drive is connected and mounted. ##########"
else
    echo "########## The drive is not connected or mounted. ##########"

    # Try to mount the drive
    sudo mount -U $uuid $BackupDir 2>/dev/null

    # Check if the drive is now mounted
    if [[ $(lsblk -no uuid /dev/sd*) == *"$uuid"* ]]; then
        echo "########## The drive has been successfully mounted. ##########"
    else
        echo "########## Failed to mount the drive. Exiting script. ##########"
        exit 1
    fi
fi

# Are there write and read permissions?
if [ ! -w "$BackupDir" ]; then
    echo "########## No write permissions ##########"
    exit 1
fi

clear 

## ------------------------------------------------------------------------ #

   echo "########## Restoration Started $( date ). ##########"

# -------------------------------FUNCTIONS----------------------------------------- #

# Function to restore Nextcloud settings
nextcloud_settings() {
    echo "############### Restoring Nextcloud settings... ###############"
   	# Enabling Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on
	echo

	# Stop Web Server
	systemctl stop $webserverServiceName

	# Remove the current Nextcloud folder
	mv "$NextcloudConfig" "$NextcloudConfig.bk"

    # Restore
	sudo rsync -avhP "$BackupDir/Nextcloud" "$NextcloudConfig" 

	# Restore permissions
	chmod -R 755 $NextcloudConfig
	chown -R www-data:www-data $NextcloudConfig

	# Export the database.
	mysql -u --host=localhost --user=$DBUser --password=$PDBPassword $NextcloudDatabase < "$BackupDir/Nextcloud/nextclouddb.sql"

	# Start Web Server
	systemctl start $webserverServiceName

	# Disabling Nextcloud Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off
	echo
}

# Function to restore Nextcloud DATA folder
nextcloud_data() {
    echo "############### Restoring Nextcloud DATA folder...###############"
	# Enabling Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on
	echo

    # Restore
	sudo rsync -avhP "$BackupDir/Nextcloud_datadir" "$NextcloudDataDir" 

	# Restore permissions
	chmod -R 770 $NextcloudDataDir
	chown -R www-data:www-data $NextcloudDataDir

	# Disabling Nextcloud Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off
	echo
}

# Function to perform a complete Nextcloud restore
nextcloud_complete() {
    echo "########## Performing complete Nextcloud restore...##########"
    nextcloud_settings
    nextcloud_data
}

# Check if an option was passed as an argument
if [[ ! -z $1 ]]; then
    # Execute the corresponding restore option
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
        4)
            emby_settings
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac

else
    # Display the menu to choose the Restore option
    echo "Choose a Restore option:"
    echo "1. Restore Nextcloud configurations, database, and data folder."
    echo "2. Restore Nextcloud configurations and database."
    echo "3. Restore only the Nextcloud data folder. Useful if the folder is stored elsewhere."
    echo "4. To go out."

    # Read the option entered by the user
    read option

    # Execute the corresponding restore option
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
    echo "############## Restore completed. The removable drive has been unmounted and powered off. ###########" >> "$LogFile"
    umount "/dev/disk/by-uuid/$uuid"
    sudo udisksctl power-off -b "/dev/disk/by-uuid/$uuid" >> "$LogFile"
    exit 0
fi
