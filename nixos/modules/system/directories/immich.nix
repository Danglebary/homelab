# Immich Directory Setup
# Creates required directories for Immich service containers
# Immich containers run as root and manage their own internal permissions

{ config, lib, pkgs, ... }:

{
  # Ensure required directories exist with correct permissions
  # Docker containers running as root will handle internal permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory for Redis and ML cache
    "d /var/lib/services/immich 0755 root root -"
    "d /var/lib/services/immich/redis 0755 root root -"
    "d /var/lib/services/immich/ml-cache 0755 root root -"
    
    # Immich photo/video storage on ZFS
    "d /mnt/vault/immich 0755 root root -"
  ];
}