{ config, lib, pkgs, ... }:

{
    imports = [
        ./users
        ./system
        ./groups.nix
    ];
}