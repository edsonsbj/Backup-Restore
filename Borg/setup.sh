#!/bin/bash

#
# Pre defined variables
#
BackupDir='/mnt/nextcloud_backup'
BackupRestoreConf='BackupRestore.conf'
LogFile='/var/log/Rsync-$(date +%Y-%m-%d_%H-%M).txt'
script_backup="$(dirname "${BASH_SOURCE[0]}")/Scripts/Backup-Restore/Backup.sh"
WebserverServiceName='nginx'
NextcloudConfig='/var/www/nextcloud'

# Function for error messages
errorecho() { cat <<< "$@" 1>&2; }

#
# Check for root
#
if [ "$(id -u)" != "0" ]
then
	errorecho "ERROR: This script has to be run as root!"
	exit 1
fi

#
# Gather information
#
clear

lsblk -o NAME,SIZE,RO,FSTYPE,TYPE,MOUNTPOINT,UUID,PTUUID | grep 'sd'
 
# List of available partitions
partitions=($(lsblk -o NAME,TYPE | grep 'part' | awk '{print $1}'))
num_partitions=${#partitions[@]}
 
# Check if there is at least one partition
if [ "$num_partitions" -eq 0 ]; then
    echo "No partitions found."
    exit 1
fi
 
# List available partitions with enumerated numbers
echo "Available partitions:"
for ((i = 0; i < num_partitions; i++)); do
    echo "$((i + 1)). ${partitions[i]}"
done
 
# Ask the user to choose a partition by number
read -p "Enter the desired partition number (1-$num_partitions): " partition_number
 
# Check if the partition number is valid
if ! [[ "$partition_number" =~ ^[0-9]+$ ]]; then
    echo "Invalid partition number."
    exit 1
fi
 
# Verifique se o número de partição está dentro do intervalo válido
if [ "$partition_number" -lt 1 ] || [ "$partition_number" -gt "$num_partitions" ]; then
    echo "Número de partição fora do intervalo válido."
    exit 1
fi
 
# Get the name of the selected partition
selected_partition="${partitions[$((partition_number - 1))]}"
#echo "$selected_partition"
selected_partition_cleaned=$(echo "$selected_partition" | sed 's/[└─├]//g')
#echo "$selected_partition_cleaned"
# Use the 'blkid' command to get the UUID of the selected partition
uuid="$(blkid -s UUID -o value /dev/"$selected_partition_cleaned")"
 
# Check if the UUID was found
if [ -n "$uuid" ]; then
    echo "$uuid"
else
    echo "Partition not found or UUID not available."
fi

echo "Enter the backup drive mount point here."
echo "Default: ${BackupDir}"
echo ""
read -p "Enter a directory or press ENTER if the backup directory is ${BackupDir}: " BACKUPDIR

[ -z "$BACKUPDIR" ] ||  BackupDir=$BACKUPDIR
clear

# Nextcloud Backup
read -p "Do you want to Backup Nextcloud? (y/n) " nextcloud

# Check user response
if [[ $nextcloud == "y" || $nextcloud == "y" ]]; then
     echo "Backing up Nextcloud..."
     echo "Enter the path to the Nextcloud file directory."
     echo "Usually: ${NextcloudConfig}"
     echo ""
     read -p "Enter a directory or press ENTER if the file directory is ${NextcloudConfig}: " NEXTCLOUDCONF

     [ -z "$NEXTCLOUDCONF" ] ||  NextcloudConfig=$NEXTCLOUDCONF
     clear

     echo "Enter the webserver service name."
     echo "Usually: nginx or apache2"
     echo ""
     read -p "Enter an new webserver service name or press ENTER if the webserver service name is ${WebserverServiceName}: " WEBSERVERSERVICENAME

     [ -z "$WEBSERVERSERVICENAME" ] ||  WebserverServiceName=$WEBSERVERSERVICENAME
     clear

     NextcloudDataDir=$(sudo -u www-data $NextcloudConfig/occ config:system:get datadirectory)
     DatabaseSystem=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbtype)
     NextcloudDatabase=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbname)
     DBUser=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbuser)
     DBPassword=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbpassword)
    
    clear

# Ask the user if they want to backup Emby configurations
echo "Do you want to backup Emby configurations? (y/n)"
read backup

if [[ $backup == 'y' ]]; then
    # Ask the user if they run Emby or Jellyfin
    echo "Do you run Emby or Jellyfin? Type 1 for Emby, 2 for Jellyfin."
    read choice

    while true; do
        if [[ $choice == '1' ]]; then
            # Create the Emby_Conf variable and store the output /var/lib/Emby
            Emby_Conf="/var/lib/emby"
            echo "The Emby configuration location is $Emby_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Emby configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for Emby, 2 for Jellyfin."
                read choice
            fi
        elif [[ $choice == '2' ]]; then
            # Create the Jellyfin_Conf variable and store the location /var/lib/jellyfin
            Jellyfin_Conf="/var/lib/jellyfin"
            echo "The Jellyfin configuration location is $Jellyfin_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Jellyfin configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for Emby, 2 for Jellyfin."
                read choice
            fi
        else
            echo "Invalid response. Please type 1 for Emby or 2 for Jellyfin."
            read choice
        fi
    done
else
    echo "Backup of Emby configurations not requested."
fi

echo "Do you want to backup Plex Media Server configurations? (y/n)"
read backup

if [[ $backup == 'y' ]]; then
    # Ask the user how they installed Plex Media Server
    echo "How did you install Plex Media Server? Type 1 for .deb packages or apt install plexmediaserver, 2 for snap install plexmediaserver."
    read choice

    while true; do
        if [[ $choice == '1' ]]; then
            # Store the path /var/lib/plexmediaserver in the Plex_Conf variable
            Plex_Conf="/var/lib/plexmediaserver"
            echo "The Plex Media Server configuration location is $Plex_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Plex Media Server configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for .deb packages or apt install plexmediaserver, 2 for snap install plexmediaserver."
                read choice
            fi
        elif [[ $choice == '2' ]]; then
            # Store the path /var/snap/plexmediaserver in the Plex_Conf variable
            Plex_Conf="/var/snap/plexmediaserver"
            echo "The Plex Media Server configuration location is $Plex_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Plex Media Server configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for .deb packages or apt install plexmediaserver, 2 for snap install plexmediaserver."
                read choice
            fi
        else
            echo "Invalid response. Please type 1 for .deb packages or apt install plexmediaserver, or 2 for snap install plexmediaserver."
            read choice
        fi
    done
else
    echo "Backup of Plex Media Server configurations not requested."
fi

    echo "UUID: ${uuid}"
    echo "BackupDir: ${BackupDir}"
    echo "WebserverServiceName: ${WebserverServiceName}"
    echo "NextcloudConfig: ${NextcloudConfig}"
    echo "NextcloudDataDir: ${NextcloudDataDir}"
    echo "Emby_Conf: ${Emby_Conf}"
    echo "Jellyfin_Conf ${Jellyfin_Conf}"
    echo "Plex_Conf: ${Plex_Conf}"

read -p "Is the information correct? [y/n] " CORRECTINFO

if [ "$CORRECTINFO" != 'y' ] ; then
  echo ""
  echo "ABORTING!"
  echo "No file has been altered."
  exit 1
fi

else
     echo "Backup will not be done."
fi

clear

{ echo "# Configuration for Backup-Restore scripts"
  echo ""
  echo "# TODO: The uuid of the backup drive"
  echo "uuid='$'"
  echo ""
  echo "# TODO: The Backup Drive Mount Point"
  echo "BackupDir='$BackupDir'"
  echo ""
  echo "# TODO: The service name of the web server. Used to start/stop web server (e.g. 'systemctl start <WebserverServiceName>')"
  echo "WebserverServiceName='$WebserverServiceName'"
  echo ""  
  echo "# TODO: The directory of your Nextcloud installation (this is a directory under your web root)"
  echo "NextcloudConfig='$NextcloudConfig'"
  echo ""
  echo "# TODO: The directory of your Nextcloud data directory (outside the Nextcloud file directory)"
  echo "# If your data directory is located in the Nextcloud files directory (somewhere in the web root),"
  echo "# the data directory must not be a separate part of the backup"
  echo "NextcloudDataDir='$NextcloudDataDir'"
  echo ""
  echo "# TODO: The name of the database system (one of: mysql, mariadb, postgresql)"
  echo "# 'mysql' and 'mariadb' are equivalent, so when using 'mariadb', you could also set this variable to 'mysql'" and vice versa.
  echo "DatabaseSystem='$DatabaseSystem'"
  echo ""
  echo "# TODO: Your Nextcloud database name"
  echo "NextcloudDatabase='$NextcloudDatabase'"
  echo ""
  echo "# TODO: Your Nextcloud database user"
  echo "DBUser='$DBUser'"
  echo ""
  echo "# TODO: The password of the Nextcloud database user"
  echo "DBPassword='$DBPassword'"
  echo ""
  echo "# TODO: The directory where the Emby or Jellyfin settings are stored (this directory is stored within /var/lib)"
  echo "Emby_Conf='$Emby_Conf'"
  echo "Jellyfin_Conf='$Jellyfin_Conf'"
  echo ""
  echo "# TODO: The directory where the Plex Media Server settings are stored (this directory is stored within /var/lib)"
  echo "Plex_Conf='$Plex_Conf'"
  echo ""
  echo "# Log File"
  echo "LogFile='$LogFile'"

 } > ./"${BackupRestoreConf}"

# Ask user about backup time
echo "Please enter the backup time in 24h format (MM:HH)"
read time

# Ask the user about the day of the week
echo "Do you want to run the backup on a specific day of the week? (y/n)"
read reply_day

if [ "$reply_day" == "s" ]; then
    echo "Please enter the day of the week (0-6 where 0 is Sunday and 6 is Saturday)"
    read day_week
else
    day_week="*"
fi

# Add the task to cron
(crontab -l 2>/dev/null; echo "$time * * $day_week $script_backup") | crontab -

echo ""
echo "Done!"
echo ""
echo ""
echo "IMPORTANT: Please check $BackupRestoreConf if all variables were set correctly BEFORE running the backup/restore scripts!"
