# Anime Content Group Module
# Controls anime media directory for both shows and movies
# Used by sonarr.anime, radarr.anime, and plex services

{ config, lib, pkgs, ... }:

{
  users.groups.anime = {
    gid = 3010;  # Anime content group
  };

  # Create anime media directory with proper permissions
  systemd.tmpfiles.rules = [
    # Anime media directory (setgid bit ensures group inheritance)
    "d /mnt/vault/media/anime 2775 root anime -"
  ];
}