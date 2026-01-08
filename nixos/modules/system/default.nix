{ config, lib, pkgs, ... }:

{
    imports = [
        ./file-system
        ./network
        ./groups.nix
        ./localization.nix
        ./users.nix
    ];
}