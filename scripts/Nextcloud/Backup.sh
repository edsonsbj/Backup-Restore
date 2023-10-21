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

# Function to backup Nextcloud settings
nextcloud_settings() {
    echo "############### Backing up Nextcloud settings... ###############" >> $LogFile
   	# Enabling Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on >> $LogFile
	echo

	# Stop Web Server
	systemctl stop $webserverServiceName

    # Backup
	sudo rsync -avhP --delete --exclude '*/data/' "$NextcloudConfig" "$BackupDir/Nextcloud" 1>> $LogFile

	# Export the database.
	mysqldump --quick -n --host=localhost $NextcloudDatabase --user=$DBUser --password=$DBPassword > "$BackupDir/Nextcloud/nextclouddb_.sql" >> $LogFile

	# Start Web Server
	systemctl start $webserverServiceName

	# Disabling Nextcloud Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off >> $LogFile
	echo
}

# Function to backup Nextcloud DATA folder
nextcloud_data() {
    echo "############### Backing up Nextcloud DATA folder...###############" >> $LogFile
	# Enabling Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on >> $LogFile
	echo

    # Backup
	sudo rsync -avhP --delete --exclude '*/files_trashbin/' "$NextcloudDataDir" "$BackupDir/Nextcloud_datadir" 1>> $LogFile

	# Disabling Nextcloud Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off >> $LogFile
	echo
}

# Function to perform a complete Nextcloud backup
nextcloud_complete() {
    echo "########## Performing complete Nextcloud backup...##########"
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
        *)
            echo "Invalid option!"
            ;;
    esac

else
    # Display the menu to choose the restore option
    echo "Choose a restore option:"
    echo "1. Backup Nextcloud configurations, database, and data folder."
    echo "2. Backup Nextcloud configurations and database."
    echo "3. Backup only the Nextcloud data folder. Useful if the folder is stored elsewhere."
    echo "4. To go out

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
        5)
            echo "Leaving the script."
            exit 0
            ;;            
        *)
            echo "Invalid option!"
            ;;
    esac
fi

  # Worked well? Unmount.
  [ "$?" = "0" ] && {
    echo "############## Backup completed. The removable drive has been unmounted and powered off. ###########" >> $LogFile
 	eval umount /dev/disk/by-uuid/$uuid
	eval sudo udisksctl power-off -b /dev/disk/by-uuid/$uuid >>$LogFile
    exit 0
  }
}
