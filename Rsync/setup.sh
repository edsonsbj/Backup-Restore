#!/bin/bash

#
# Pre defined variables
#
BackupDir='/mnt/nextcloud_backup'
NextcloudConfig='/var/www/nextcloud'
BackupRestoreConf='BackupRestore.conf'

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

echo "Enter the path to the Nextcloud file directory."
echo "Usually: ${NextcloudConfig}"
echo ""
read -p "Enter a directory or press ENTER if the file directory is ${NextcloudConfig}: " NEXTCLOUDCONF

[ -z "$NEXTCLOUDCONF" ] ||  NextcloudConfig=$NEXTCLOUDCONF
clear

echo "UUID: ${uuid}"
echo "BackupDir: ${BackupDir}"
echo "NextcloudConfig: ${NextcloudConfig}"
echo "NextcloudDataDir: ${NextcloudDataDir}"

read -p "Is the information correct? [y/N] " CORRECTINFO

if [ "$CORRECTINFO" != 'y' ] ; then
  echo ""
  echo "ABORTING!"
  echo "No file has been altered."
  exit 1
fi

{ echo "# Configuration for Backup-Restore scripts"
  echo ""
  echo "# TODO: The uuid of the backup drive"
  echo "uuid='$uuid'"
  echo ""
  echo "# TODO: The Backup Drive Mount Point"
  echo "BackupDir='$BackupDir'"
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
  echo "# Backup Destinations"

  echo ""
  echo "# Log File"
  echo "LOG_PATH='/var/log/'"

 } > ./"${BackupRestoreConf}"

echo ""
echo "Done!"
echo ""
echo ""
echo "IMPORTANT: Please check $BackupRestoreConf if all variables were set correctly BEFORE running the backup/restore scripts!"
