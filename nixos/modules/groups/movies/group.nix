# Movies Content Group Module
# Controls movies media directory (non-anime content)
# Used by radarr.movies and plex services

{ config, lib, pkgs, ... }:

{
  users.groups.movies = {
    gid = 3012;  # Movies content group
  };

  # Create movies media directory with proper permissions
  systemd.tmpfiles.rules = [
    # Movies media directory (setgid bit ensures group inheritance)
    "d /mnt/vault/media/movies 2775 root movies -"
  ];
}