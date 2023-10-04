#!/bin/bash

#
# Pre defined variables
#
BackupDir='/mnt/nextcloud_backup'
NextcloudConfig='/var/www/nextcloud'
NextcloudDataDir=$(sudo -u www-data $NextcloudConfig/occ config:system:get datadirectory)
DatabaseSystem=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbtype)
NextcloudDatabase=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbname)
DBUser=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbuser)
DBPassword=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbpassword)
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

# echo "Enter the directory to which the backups should be saved."
echo "Enter the UUID of the drive"
echo "Default: ${uuid}"
echo ""
read -p "Enter the UUID corresponding to the unit that will serve as a backup or press ENTER if the UUID is ${uuid}: " UUID

[ -z "$UUID" ] ||  uuid=$UUID
clear

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
