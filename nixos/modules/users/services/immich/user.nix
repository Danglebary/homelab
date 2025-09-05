# Immich Service User Module
# Photo management and sharing service
# Self-hosting service for family photo management

{ config, lib, pkgs, ... }:

{
  users.users.immich = {
    isSystemUser = true;
    group = "services";
    uid = 2050;  # Consistent UID for Docker containers
    home = "/var/lib/services/immich";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (immich manages internal structure)
    "d /var/lib/services/immich 0755 immich services -"

    # Service logging directory for local log storage
    "d /var/log/services/immich 0755 immich services -"
  ];
}