# Prometheus Service User Module
# Time-series metrics collection and storage
# Observability service for collecting metrics from all homelab services

{ config, lib, pkgs, ... }:

{
  users.users.prometheus = {
    isSystemUser = true;
    group = "services";
    uid = 2042;  # Consistent UID for Docker containers
    home = "/var/lib/services/prometheus";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (prometheus manages internal structure)
    "d /var/lib/services/prometheus 0755 prometheus services -"

    # Service logging directory for local log storage
    "d /var/log/services/prometheus 0755 prometheus services -"
  ];
}