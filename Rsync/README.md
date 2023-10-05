# Backup-Restore

Bash scripts for backup/restore of [Nextcloud](https://nextcloud.com/) [Emby](https://emby.media/) [Jellyfin](https://jellyfin.org/) [Plex](https://www.plex.tv/).

## General information

For a full backup of any Nextcloud instance along with a multimedia server like Plex, you will have to back up these items:
- The Nextcloud **file directory** (usually */var/www/nextcloud*)
- The **data directory** of Nextcloud (it's recommended that this is *not* located in the web root, so e.g. */var/nextcloud_data*)
- The Nextcloud **database**