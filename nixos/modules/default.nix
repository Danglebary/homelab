# NixOS Modules - Homelab Service Users and Groups

{ config, lib, pkgs, ... }:

{
  imports = [
    # Group modules
    ./groups/services/group.nix
    ./groups/downloads/group.nix
    ./groups/transcoding/group.nix
    ./groups/anime/group.nix
    ./groups/shows/group.nix
    ./groups/movies/group.nix
    ./groups/cleanup/group.nix

    # Service user modules
    ./users/services/prowlarr/user.nix
    ./users/services/overseerr/user.nix
    ./users/services/deluge/user.nix
    ./users/services/tdarr/user.nix
    ./users/services/plex/user.nix
    ./users/services/sonarr/shows/user.nix
    ./users/services/sonarr/anime/user.nix
    ./users/services/radarr/movies/user.nix
    ./users/services/radarr/anime/user.nix
    ./users/services/profilarr/user.nix
    ./users/services/gluetun/user.nix
    ./users/services/pihole/user.nix
    ./users/services/homepage/user.nix
    ./users/services/alloy/user.nix
    ./users/services/loki/user.nix
    ./users/services/prometheus/user.nix
    ./users/services/grafana/user.nix
    ./system/directories/immich.nix
    ./system/network
    ./users/services/nextcloud/user.nix
  ];
}