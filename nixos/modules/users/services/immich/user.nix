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
    # Service runtime directory (775 allows group write access for containers)
    "d /var/lib/services/immich 0775 immich services -"
    "d /var/lib/services/immich/postgres 0775 immich services -"
    "d /var/lib/services/immich/redis 0775 immich services -"
    "d /var/lib/services/immich/ml-cache 0775 immich services -"

    # Service logging directory for local log storage
    "d /var/log/services/immich 0775 immich services -"
  ];
}