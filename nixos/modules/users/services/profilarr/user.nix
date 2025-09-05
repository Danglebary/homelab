# Profilarr Service User Module
# Automated custom formats and quality profiles management
# API-based service, no direct media access needed

{ config, lib, pkgs, ... }:

{
  users.users.profilarr = {
    isSystemUser = true;
    group = "services";
    uid = 2016;  # Consistent UID for Docker containers
    home = "/var/lib/services/profilarr";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (profilarr manages internal structure)
    "d /var/lib/services/profilarr 0755 profilarr services -"

    # Service logging directory for local log storage
    "d /var/log/services/profilarr 0755 profilarr services -"
  ];
}