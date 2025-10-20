{ config, lib, pkgs, ... }:

{
  imports = [
    ./gluetun.nix
    ./immich.nix
  ];
}