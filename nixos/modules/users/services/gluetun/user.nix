# Gluetun Service User Module
# VPN gateway with kill-switch for torrent traffic isolation
# Infrastructure service providing VPN networking to other services

{ config, lib, pkgs, ... }:

{
  users.users.gluetun = {
    isSystemUser = true;
    group = "services";
    uid = 2030;  # Consistent UID for Docker containers
    home = "/var/lib/services/gluetun";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (gluetun manages internal structure)
    "d /var/lib/services/gluetun 0755 gluetun services -"
  ];
}