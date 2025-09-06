# Service User Modules - Auto-Discovery  
# Imports all service user definitions for homelab services
# Note: Immich is intentionally omitted as it runs as root in containers

{ config, lib, pkgs, ... }:

{
  imports = [
    # Media management services
    ./prowlarr/user.nix
    ./overseerr/user.nix
    ./plex/user.nix
    
    # Download and processing services  
    ./deluge/user.nix
    ./tdarr/user.nix
    
    # Content categorization services
    ./sonarr/shows/user.nix
    ./sonarr/anime/user.nix
    ./radarr/movies/user.nix
    ./radarr/anime/user.nix
    ./profilarr/user.nix
    
    # Network and infrastructure services
    ./gluetun/user.nix
    ./pihole/user.nix
    ./homepage/user.nix
    
    # Observability services
    ./alloy/user.nix
    ./loki/user.nix
    ./prometheus/user.nix
    ./grafana/user.nix
    
    # Cloud services
    ./nextcloud/user.nix
  ];
}