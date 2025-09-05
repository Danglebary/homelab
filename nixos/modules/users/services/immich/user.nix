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
    # PostgreSQL data is now managed by Docker named volume
    "d /var/lib/services/immich/redis 0775 immich services -"
    "d /var/lib/services/immich/ml-cache 0775 immich services -"

    # Service logging directory for local log storage
    "d /var/log/services/immich 0775 immich services -"
    
    # Immich photo/video storage on ZFS (container needs write access)
    "d /mnt/vault/immich 0775 immich services -"
    # Immich required subdirectories for system integrity checks
    "d /mnt/vault/immich/upload 0775 immich services -"
    "d /mnt/vault/immich/library 0775 immich services -"
    "d /mnt/vault/immich/thumbs 0775 immich services -"
    "d /mnt/vault/immich/encoded-video 0775 immich services -"
    "d /mnt/vault/immich/profile 0775 immich services -"
    "d /mnt/vault/immich/backups 0775 immich services -"
  ];
}