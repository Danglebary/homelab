{ config, lib, pkgs, ... }:

{
    imports = [
        ./admin.nix
        ./dev.nix
        ./halfblown.nix
        ./service.nix
    ];
}