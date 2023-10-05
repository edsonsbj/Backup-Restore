#!/bin/bash

CONFIG="$(dirname "${BASH_SOURCE[0]}")/.conf"
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

	# Export the database.
	mysqldump --quick -n --host=$HOSTNAME $NextcloudDatabase --user=$DBUser --password=$DBPassword > "$BackupDir/Nextcloud/nextclouddb_.sql" >> $LogFile

    # Backup
	sudo rsync -avhP --delete --exclude '*/data/' "$NextcloudConfig" "$BackupDir/Nextcloud" 1>> $LogFile

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

# Function to backup Emby settings
emby_settings() {
    echo "########## Backing up Emby Server settings...##########" >> $LogFile
    # Stop Emby
    sudo systemctl stop emby-server.service

    # Backup
    sudo rsync -avhP --delete --exclude '*/cache' --exclude '*/logs' --exclude '*/transcoding-temp' "$Emby_Conf" "$BackupDir/emby" 1>> $LogFile
 
    # Start Emby
    sudo systemctl start emby-server.service
}

# Function to backup Emby Media Server and Nextcloud settings
nextcloud_and_emby_settings() {
    echo "########## Backing up Emby Media Server and Nextcloud settings...##########"
    nextcloud_settings
    emby_settings
}

# Function to backup Jellyfin settings
jellyfin_settings() {
    echo "########## Backing up Jellyfin settings...##########" >> $LogFile
    # Stop Jellyfin
    sudo systemctl stop jellyfin.service

    # Backup
    sudo rsync -avhP --delete --exclude '*/cache' --exclude '*/logs' --exclude '*/transcoding-temp' "$Jellyfin_Conf" "$BackupDir/jellyfin" 1>> $LogFile

    # Start Jellyfin
    sudo systemctl start jellyfin.service
}

# Function to backup Jellyfin and Nextcloud settings
nextcloud_and_jellyfin_settings() {
    echo "########## Backing up Jellyfin and Nextcloud settings...##########"
    nextcloud_settings
    jellyfin_settings
}

# Function to backup Plex settings
plex_settings() {
    echo "########## Backing up Plex Media Server settings...##########" >> $LogFile
    # Stop Plex
    sudo systemctl stop plexmediaserver

    # Backup
    sudo rsync -avhP --delete --exclude '*/Cache' --exclude '*/Crash Reports' --exclude '*/Diagnostics' --exclude '*/Logs' "$Plex_Conf" "$BackupDir/Plex" 1>> $LogFile

    # Start Plex
    sudo systemctl start plexmediaserver
}

# Function to backup Plex Media Server and Nextcloud settings
nextcloud_and_plex_settings() {
    echo "########## Backing up Plex Media Server and Nextcloud settings...##########"
    nextcloud_settings
    plex_settings
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
        5)
            nextcloud_and_emby_settings
            ;;
        6)
            nextcloud_complete_and_emby_settings
            ;;
        7)
            jellyfin_settings
            ;;
        8)
            nextcloud_and_jellyfin_settings
            ;;
        9)
            nextcloud_complete_and_jellyfin_settings
            ;;
        10)
            plex_settings
            ;;
        11)
            nextcloud_and_plex_settings
            ;;
        12)
            nextcloud_complete_and_plex_settings
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac

else
    # Display the menu to choose the restore option
    echo "Choose a restore option:"
    echo "	 1	>> Backup Nextcloud configurations, database, and data folder."
    echo "	 2	>> Backup Nextcloud configurations and database."
    echo "	 3	>> Backup only the Nextcloud data folder. Useful if the folder is stored elsewhere."
    echo "	 4	>> Backup Emby Media Server settings."
    echo "	 5	>> Backup Nextcloud and Emby Settings."
    echo "	 6	>> Backup Nextcloud settings, database and data folder, as well as Emby settings."
    echo "	 7	>> Backup Jellyfin Settings."
    echo "	 8	>> Backup Nextcloud and Jellyfin Settings."
    echo "	 9	>> Backup Nextcloud settings, database and data folder, as well as Jellyfin settings."
    echo "	10	>> Backup Plex Media Server Settings."
    echo "	11	>> Backup Nextcloud and Plex Media Server Settings."
    echo "	12	>> Backup Nextcloud settings, database and data folder, as well as Plex Media Server settings."

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
            emby_settings
            ;;
        5)
            nextcloud_and_emby_settings
            ;;
        6)
            nextcloud_complete_and_emby_settings
            ;;
        7)
            jellyfin_settings
            ;;
        8)
            nextcloud_and_jellyfin_settings
            ;;
        9)
            nextcloud_complete_and_jellyfin_settings
            ;;
        10)
            plex_settings
            ;;
        11)
            nextcloud_and_plex_settings
            ;;
        12)
            nextcloud_complete_and_plex_settings
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
