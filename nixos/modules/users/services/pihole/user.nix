# Pi-hole Service User Module
# DNS and ad blocking service for entire network
# Infrastructure service providing DNS to home network

{ config, lib, pkgs, ... }:

{
  users.users.pihole = {
    isSystemUser = true;
    group = "services";
    uid = 2031;  # Consistent UID for Docker containers
    home = "/var/lib/services/pihole";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (pihole manages internal structure)
    "d /var/lib/services/pihole 0755 pihole services -"

    # Service logging directory for local log storage
    "d /var/log/services/pihole 0755 pihole services -"
  ];
}