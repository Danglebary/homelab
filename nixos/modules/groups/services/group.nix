# Services Base Group Module
# Single consolidated group for all homelab services
# Manages all service-related directory permissions

{ config, lib, pkgs, ... }:

{
  users.groups.service = {
    gid = 3000;  # Service group for all homelab services
  };

  # Create all service directories with proper permissions
  systemd.tmpfiles.rules = [
    # Media directories (setgid bit ensures group inheritance)
    "d /mnt/vault/media/anime 2775 service service -"
    "d /mnt/vault/media/movies 2775 service service -"
    "d /mnt/vault/media/shows 2775 service service -"

    # Processing directories
    "d /mnt/vault/temp/downloads 2775 service service -"
    "d /mnt/vault/temp/downloads/pending 2775 service service -"
    "d /mnt/vault/temp/downloads/completed 2775 service service -"
    "d /mnt/vault/temp/transcoded 2775 service service -"

    # Service runtime and logging directories
    "d /var/lib/services 2775 service service -"
    "d /var/log/services 2775 service service -"
  ];
}