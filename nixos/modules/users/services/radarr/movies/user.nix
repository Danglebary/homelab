# Radarr Movies Service User Module
# Movie management and automation (non-anime content)
# Manages movies library and imports from transcoded directory

{ config, lib, pkgs, ... }:

{
  users.users."radarr.movies" = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "movies" ];
    uid = 2014;  # Consistent UID for Docker containers
    home = "/var/lib/services/radarr/movies";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (radarr manages internal structure)
    "d /var/lib/services/radarr 0755 root services -"
    "d /var/lib/services/radarr/movies 0755 radarr.movies services -"

    # Service logging directory for local log storage
    "d /var/log/services/radarr/movies 0755 radarr.movies services -"
  ];
}