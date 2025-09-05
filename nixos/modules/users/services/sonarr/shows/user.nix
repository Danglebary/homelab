# Sonarr TV Shows Service User Module
# TV show management and automation (non-anime content)
# Manages shows library and imports from transcoded directory

{ config, lib, pkgs, ... }:

{
  users.users."sonarr.shows" = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "shows" ];
    uid = 2012;  # Consistent UID for Docker containers
    home = "/var/lib/services/sonarr/shows";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (sonarr manages internal structure)
    "d /var/lib/services/sonarr 0755 root services -"
    "d /var/lib/services/sonarr/shows 0755 sonarr.shows services -"
    
    # Service logging directory for local log storage
    "d /var/log/services 0755 root root -"
    "d /var/log/services/sonarr.shows 0755 sonarr.shows services -"
  ];
}