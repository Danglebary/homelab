{ config, lib, pkgs, ... }:

{
    imports = [
        ./services
        ./network.nix
        ./directories.nix
    ];
}