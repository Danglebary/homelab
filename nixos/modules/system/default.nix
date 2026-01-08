{ config, lib, pkgs, ... }:

{
    imports = [
        ./file-system
        ./localization.nix
        ./groups.nix
        ./users.nix
        ./network
    ];
}