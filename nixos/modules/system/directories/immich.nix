# Immich Directory Setup
# Creates required directories for Immich service containers
# Uses simplified service user/group model

{ config, lib, pkgs, ... }:

{
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory for ML cache
    "d /var/lib/services/immich 2775 service service -"
    "d /var/lib/services/immich/ml-cache 2775 service service -"

    # Immich photo/video storage on ZFS
    "d /mnt/vault/immich 2775 service service -"
  ];
}