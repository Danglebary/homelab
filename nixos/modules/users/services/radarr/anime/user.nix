# Radarr Anime Service User Module
# Anime movie management and automation
# Manages anime library and imports from transcoded directory

{ config, lib, pkgs, ... }:

{
  users.users."radarr.anime" = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "anime" ];
    uid = 2015;  # Consistent UID for Docker containers
    home = "/var/lib/services/radarr/anime";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (radarr manages internal structure)
    "d /var/lib/services/radarr/anime 0755 radarr.anime services -"
  ];
}