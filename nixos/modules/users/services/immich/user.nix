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
    # Service runtime directory (containers run as UID 1000 node user)
    "d /var/lib/services/immich 0755 2050 3000 -"
    # PostgreSQL data is now managed by Docker named volume
    "d /var/lib/services/immich/redis 0755 2050 3000 -"
    "d /var/lib/services/immich/ml-cache 0755 2050 3000 -"

    # Service logging directory for local log storage
    "d /var/log/services/immich 0755 2050 3000 -"
    
    # Immich photo/video storage on ZFS (container creates subdirectories as needed)
    "d /mnt/vault/immich 0775 2050 3000 -"
  ];
}