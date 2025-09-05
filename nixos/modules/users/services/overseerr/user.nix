# Overseerr Service User Module
# Media request interface for family/friends
# Forwards requests to Sonarr/Radarr instances

{ config, lib, pkgs, ... }:

{
  users.users.overseerr = {
    isSystemUser = true;
    group = "services";
    uid = 2011;  # Consistent UID for Docker containers
    home = "/var/lib/services/overseerr";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (overseerr manages internal structure)
    "d /var/lib/services/overseerr 0755 overseerr services -"

    # Service logging directory for local log storage
    "d /var/log/services/overseerr 0755 overseerr services -"
  ];
}