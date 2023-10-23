# Backup-Restore

Bash scripts for backup/restore of [Nextcloud](https://nextcloud.com/) and media servers as [Emby](https://emby.media/) [Jellyfin](https://jellyfin.org/) and [Plex](https://www.plex.tv/) that are installed in the same location.

## General information

For a full backup of any Nextcloud instance along with a multimedia server like Plex, you will have to back up these items:
- The Nextcloud **file directory** (usually */var/www/nextcloud*)
- The **data directory** of Nextcloud (it's recommended that this is *not* located in the web root, so e.g. */var/nextcloud_data*)
- The Nextcloud **database**
- The Media server  **file directory** (usually */var/lib or /var/snap*)

With these scripts, all these elements can be included in a backup.

## Important notes about using the scripts

- After cloning or downloading the scripts, these need to be set up by running the script `setup.sh` (see below).
- If you do not want to use the automated setup, you can also use the file `BackupRestore.conf.sample` as a starting point. Just make sure to rename the file when you are done (`cp BackupRestore.conf.sample BackupRestore.conf`)
- The configuration file `BackupRestore.conf` has to be located in the same directory as the scripts for backup/restore.

## Setup

1. Run the following command at a terminal with administrator privileges 
```
wget https://raw.githubusercontent.com/edsonsbj/Backup-Restore/main/setup.sh && sudo chmod 700 *.sh && ./sudo setup.sh
```
2. After running the `setup.sh` interactive script, the `Backup.sh` and `Restore.sh` scripts will be generated based on your selection, along with the `BackupRestore.conf` for using the script, in addition to configuring cron.
3. **Important**: check that all files were created and must be in /root/Scripts. 
4. **Important**: Check this configuration file if everything was set up correctly (see *TODO* in the configuration file comments)
5. Start using the scripts: See sections *Backup* and *Restore* below

Keep in mind that the configuration file `BackupRestore.conf` hast to be located in the same directory as the scripts for backup/restore, otherwise the configuration will not be found.

## Performing Backup or Restoration

Call the script

```
sudo ./Backup.sh
```  

You can also call this script by cron. Example (at 2am every night.

```
0 2 * * * sudo /path/to/scripts/Backup-Restore/Backup.sh
```
