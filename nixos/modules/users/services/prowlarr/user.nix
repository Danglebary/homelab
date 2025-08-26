# Prowlarr Service User Module
# Indexer management service for *arr stack
# Part of the media domain group

{ config, lib, pkgs, ... }:

{
  users.users.prowlarr = {
    isSystemUser = true;
    group = "services";
    uid = 2010;  # Consistent UID for Docker containers
    home = "/var/lib/services/prowlarr";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (prowlarr manages internal structure)
    "d /var/lib/services/prowlarr 0755 prowlarr services -"
  ];
}