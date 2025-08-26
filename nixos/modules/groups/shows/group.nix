# Shows Content Group Module
# Controls TV shows media directory (non-anime content)
# Used by sonarr.shows and plex services

{ config, lib, pkgs, ... }:

{
  users.groups.shows = {
    gid = 3011;  # TV shows content group
  };

  # Create shows media directory with proper permissions
  systemd.tmpfiles.rules = [
    # Shows media directory (setgid bit ensures group inheritance)
    "d /mnt/vault/media/shows 2775 root shows -"
  ];
}