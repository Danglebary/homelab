{ config, lib, pkgs, ... }:

{
    imports = [
        ./deluge.nix
        ./prowlarr.nix
        ./flaresolverr.nix
        ./radarr.nix
        ./sonarr.nix
        ./homepage.nix
        # ./plex.nix
        ./overseerr.nix
    ];
}