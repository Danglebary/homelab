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
    "d /var/lib/services/immich 0755 1000 1000 -"
    # PostgreSQL data is now managed by Docker named volume
    "d /var/lib/services/immich/redis 0755 1000 1000 -"
    "d /var/lib/services/immich/ml-cache 0755 1000 1000 -"

    # Service logging directory for local log storage
    "d /var/log/services/immich 0755 1000 1000 -"
    
    # Immich photo/video storage on ZFS (container needs write access)
    "d /mnt/vault/immich 0755 1000 1000 -"
    # Immich required subdirectories for system integrity checks
    "d /mnt/vault/immich/upload 0755 1000 1000 -"
    "d /mnt/vault/immich/library 0755 1000 1000 -"
    "d /mnt/vault/immich/thumbs 0755 1000 1000 -"
    "d /mnt/vault/immich/encoded-video 0755 1000 1000 -"
    "d /mnt/vault/immich/profile 0755 1000 1000 -"
    "d /mnt/vault/immich/backups 0755 1000 1000 -"
  ];
}