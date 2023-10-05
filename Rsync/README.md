# Backup-Restore

Bash scripts for backup/restore of [Nextcloud](https://nextcloud.com/) [Emby](https://emby.media/) [Jellyfin](https://jellyfin.org/) [Plex](https://www.plex.tv/).

## General information

For a full backup of any Nextcloud instance along with a multimedia server like Plex, you will have to back up these items:
- The Nextcloud **file directory** (usually */var/www/nextcloud*)
- The **data directory** of Nextcloud (it's recommended that this is *not* located in the web root, so e.g. */var/nextcloud_data*)
- The Nextcloud **database**
- The Multimedia Server **file directory** (usually */var/lib or /var/snap*)

With these scripts, all these elements can be included in a backup.

## Important notes about using the scripts

- After cloning or downloading the scripts, these need to be set up by running the script `setup.sh` (see below).
- If you do not want to use the automated setup, you can also use the file `BackupRestore.conf.sample` as a starting point. Just make sure to rename the file when you are done (`cp BackupRestore.conf.sample BackupRestore.conf`)
- The configuration file `BackupRestore.conf` has to be located in the same directory as the scripts for backup/restore.