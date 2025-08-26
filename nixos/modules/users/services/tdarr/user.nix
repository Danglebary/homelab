# Tdarr Service User Module
# Automated transcoding/re-encoding service
# Reads from downloads/completed, creates new files in transcoded directory

{ config, lib, pkgs, ... }:

{
  users.users.tdarr = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "transcoding" ];
    uid = 2021;  # Consistent UID for Docker containers
    home = "/var/lib/services/tdarr";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (tdarr manages internal structure)
    "d /var/lib/services/tdarr 0755 tdarr services -"
  ];
}