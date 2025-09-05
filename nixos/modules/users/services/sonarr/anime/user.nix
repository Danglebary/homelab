# Sonarr Anime Service User Module
# Anime show management and automation
# Manages anime library and imports from transcoded directory

{ config, lib, pkgs, ... }:

{
  users.users."sonarr.anime" = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "anime" ];
    uid = 2013;  # Consistent UID for Docker containers
    home = "/var/lib/services/sonarr/anime";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (sonarr manages internal structure)
    "d /var/lib/services/sonarr/anime 0755 sonarr.anime services -"

    # Service logging directory for local log storage
    "d /var/log/services/sonarr/anime 0755 sonarr.anime services -"
  ];
}