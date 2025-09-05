# Homepage Service User Module
# Admin dashboard and service status overview
# Infrastructure service providing central service access

{ config, lib, pkgs, ... }:

{
  users.users.homepage = {
    isSystemUser = true;
    group = "services";
    uid = 2032;  # Consistent UID for Docker containers
    home = "/var/lib/services/homepage";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (homepage manages internal structure)
    "d /var/lib/services/homepage 0755 homepage services -"

    # Service logging directory for local log storage
    "d /var/log/services/homepage 0755 homepage services -"
  ];
}