# Grafana Service User Module
# Unified observability dashboards and visualization
# Observability service for visualizing metrics, logs, and traces

{ config, lib, pkgs, ... }:

{
  users.users.grafana = {
    isSystemUser = true;
    group = "services";
    uid = 2043;  # Consistent UID for Docker containers
    home = "/var/lib/services/grafana";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (grafana manages internal structure)
    "d /var/lib/services/grafana 0755 grafana services -"

    # Service logging directory for local log storage
    "d /var/log/services/grafana 0755 grafana services -"
  ];
}