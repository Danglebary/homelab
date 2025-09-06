{ config, lib, pkgs, ... }:

{
  imports = [
    ./cloudflared.nix
  ];
}