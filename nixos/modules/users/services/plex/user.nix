# Plex Service User Module
# Media streaming server with hardware transcoding
# Needs read/write access to all media directories for metadata management

{ config, lib, pkgs, ... }:

{
  users.users.plex = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "anime" "shows" "movies" ];
    uid = 2001;  # Consistent UID for Docker containers
    home = "/var/lib/services/plex";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (plex manages internal structure)
    "d /var/lib/services/plex 0755 plex services -"
    
    # Service logging directory for local log storage
    "d /var/log/services/plex 0755 plex services -"
  ];
}