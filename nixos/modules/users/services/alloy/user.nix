# Alloy Service User Module
# Unified telemetry collection for logs, metrics, and traces
# Observability service collecting data from all homelab services

{ config, lib, pkgs, ... }:

{
  users.users.alloy = {
    isSystemUser = true;
    group = "services";
    uid = 2040;  # Consistent UID for Docker containers
    home = "/var/lib/services/alloy";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (alloy manages internal structure)
    "d /var/lib/services/alloy 0755 alloy services -"
  ];
}