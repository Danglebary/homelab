{ config, lib, pkgs, ... }:

{
    imports = [
        ./deluge.nix
        # ./prowlarr.nix
        # ./radarr.nix
        # ./sonarr.nix
        # ./plex.nix
        # ./overseerr.nix
    ];
}