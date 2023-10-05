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
if [[ $(lsblk -no UUID /dev/sd*) == *"$UUID"* ]]; then
    echo "########## The drive is connected and mounted. ##########"
    sudo mount -U $UUID $BackupDir
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
echo "restore file location db is " '/'

if [ $? -eq 0 ]; then
    echo "Done"
else
    echo "failed to change to root directory. Restoration failed"
    exit 1
fi

## ------------------------------------------------------------------------ #

   echo "########## Restoration Started $( date ). ##########" >> $LogFile

# -------------------------------FUNCTIONS----------------------------------------- #

# Function to restore Nextcloud settings
nextcloud_settings() {
    echo "############### Restoring Nextcloud settings... ###############" >> $LogFile
   	# Enabling Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on >> $LogFile
	echo

	# Stop Apache
	systemctl stop apache2

	# Remove the current Nextcloud folder
	rm -rf "$NextcloudConfig"

    # Restore
	sudo rsync -avhP "$BackupDir/Nextcloud" "$NextcloudConfig" 1>> $LogFile

	# Export the database.
	mysql -u --host=localhost --user=$DBUser --password=$PDBPassword $NextcloudDatabase < "$BackupDir/Nextcloud/nextclouddb.sql" >> $LogFile

	# Start Apache
	systemctl start apache2

	# Disabling Nextcloud Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off >> $LogFile
	echo
}

# Function to restore Nextcloud DATA folder
nextcloud_data() {
    echo "############### Restoring Nextcloud DATA folder...###############" >> $LogFile
	# Enabling Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on >> $LogFile
	echo

    # Restore
	sudo rsync -avhP "$BackupDir/Nextcloud_datadir" "$NextcloudDataDir" 1>> $LogFile

	# Disabling Nextcloud Maintenance Mode
	echo
	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off >> $LogFile
	echo
}

# Function to perform a complete Nextcloud restore
nextcloud_complete() {
    echo "########## Performing complete Nextcloud restore...##########"
    nextcloud_settings
    nextcloud_data
}

# Function to restore Emby settings
emby_settings() {
    echo "########## Restoring Emby Server settings...##########" >> $LogFile
    # Stop Emby
    sudo systemctl stop emby-server.service

    # Remove the current directory from Emby
    rm -rf $Emby_Conf

    # Restore
    sudo rsync -avhP "$BackupDir/emby" "$Emby_Conf" 1>> $LogFile

    # Restore permissions
    chmod -R 755 $Emby_Conf
    chown -R emby:emby $Emby_Conf

    # Add the Plex User to the www-data group to access Nextcloud folders
    sudo adduser emby www-data

    # Start Emby
    sudo systemctl start emby-server.service
}

# Function to restore Emby Media Server and Nextcloud settings
nextcloud_and_emby_settings() {
    echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
    nextcloud_settings
    emby_settings
}

# Function to restore Emby Media Server and Nextcloud settings
nextcloud_complete_and_emby_settings() {
    echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
    nextcloud_settings
    nextcloud_data
    emby_settings
}

# Function to restore Jellyfin settings
jellyfin_settings() {
    echo "########## Restoring Jellyfin settings...##########" >> $LogFile
    # Stop Emby
    sudo systemctl stop jellyfin.service

    # Remove the current directory from Jellyfin
    rm -rf "$Jellyfin_Conf"

    # Restore
    sudo rsync -avhP "$BackupDir/jellyfin" "$Jellyfin_Conf" 1>> $LogFile

    # Restore permissions
    chmod -R 755 $Jellyfin_Conf
    chown -R jellyfin:jellyfin $Jellyfin_Conf

    # Add the Plex User to the www-data group to access Nextcloud folders
    sudo adduser jellyfin www-data

    # Start Jellyfin
    sudo systemctl start jellyfin.service
}

# Function to restore Jellyfin and Nextcloud settings
nextcloud_and_jellyfin_settings() {
    echo "########## Restoring Jellyfin and Nextcloud settings...##########"
    nextcloud_settings
    jellyfin_settings
}

# Function to restore Emby Media Server and Nextcloud settings
nextcloud_complete_and_jellyfin_settings() {
    echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
    nextcloud_settings
    nextcloud_data
    jellyfin_settings
}

# Function to restore Plex settings
plex_settings() {
    echo "########## Restoring Plex Media Server settings...##########" >> $LogFile
    # Stop Emby
    sudo systemctl stop plexmediaserver

    # Remove the current directory from Plex
    rm -rf $Plex_Conf

    # Restore 
    sudo rsync -avhP "$BackupDir/Plex" "$Plex_Conf" 1>> $LogFile

    # Restore permissions
    chmod -R 755 $Plex_Conf
    chown -R plex:plex $Plex_Conf

    # Add the Plex User to the www-data group to access Nextcloud folders
    sudo adduser plex www-data

    # Start Plex
    sudo systemctl start plexmediaserver
}

# Function to restore Plex Media Server and Nextcloud settings
nextcloud_and_plex_settings() {
    echo "########## Restoring Plex Media Server and Nextcloud settings...##########"
    nextcloud_settings
    plex_settings
}

# Function to restore Emby Media Server and Nextcloud settings
nextcloud_complete_and_plex_settings() {
    echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
    nextcloud_settings
    nextcloud_data
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
    echo "	 1	>> Restore Nextcloud configurations, database, and data folder."
    echo "	 2	>> Restore Nextcloud configurations and database."
    echo "	 3	>> Restore only the Nextcloud data folder. Useful if the folder is stored elsewhere."
    echo "	 4	>> Restore Emby Media Server settings."
    echo "	 5	>> Restore Nextcloud and Emby Settings."
    echo "	 6	>> Restore Nextcloud settings, database and data folder, as well as Emby settings."
    echo "	 7	>> Restore Jellyfin Settings."
    echo "	 8	>> Restore Nextcloud and Jellyfin Settings."
    echo "	 9	>> Restore Nextcloud settings, database and data folder, as well as Jellyfin settings."
    echo "	10	>> Restore Plex Media Server Settings."
    echo "	11	>> Restore Nextcloud and Plex Media Server Settings."
    echo "	12	>> Restore Nextcloud settings, database and data folder, as well as Plex Media Server settings."

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
    echo "############## Restore completed. The removable drive has been unmounted and powered off. ###########" >> $LogFile
 	eval umount /dev/disk/by-uuid/$UUID
	eval sudo udisksctl power-off -b /dev/disk/by-uuid/$UUID >>$LogFile
    exit 0
  }
}
