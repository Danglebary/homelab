# Nextcloud Service User Module
# File synchronization and collaboration service
# Self-hosting service for file sync and collaboration

{ config, lib, pkgs, ... }:

{
  users.users.nextcloud = {
    isSystemUser = true;
    group = "services";
    uid = 2051;  # Consistent UID for Docker containers
    home = "/var/lib/services/nextcloud";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (nextcloud manages internal structure)
    "d /var/lib/services/nextcloud 0755 nextcloud services -"

    # Service logging directory for local log storage
    "d /var/log/services/nextcloud 0755 nextcloud services -"
  ];
}