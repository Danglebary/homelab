{ config, lib, pkgs, ... }:

{
    imports = [
        ./deluge.nix
        ./flaresolverr.nix
        ./prowlarr.nix
        ./radarr.nix
        ./sonarr.nix
        ./overseerr.nix
        ./plex.nix
        ./homepage.nix
    ];
}