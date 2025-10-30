{ config, lib, pkgs, ... }:

{
  imports = [
    ./cloudflared.nix
    ./nfs-server.nix
  ];
}