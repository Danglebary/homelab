# Loki Service User Module
# Centralized log storage and querying
# Observability service for aggregating logs from all homelab services

{ config, lib, pkgs, ... }:

{
  users.users.loki = {
    isSystemUser = true;
    group = "services";
    uid = 2041;  # Consistent UID for Docker containers
    home = "/var/lib/services/loki";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (loki manages internal structure)
    "d /var/lib/services/loki 0755 loki services -"

    # Service logging directory for local log storage
    "d /var/log/services/loki 0755 loki services -"
  ];
}