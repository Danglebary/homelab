# Group Modules - Auto-Discovery
# Imports all group definitions for homelab services

{ config, lib, pkgs, ... }:

{
  imports = [
    # Media content type groups
    ./anime/group.nix
    ./movies/group.nix
    ./shows/group.nix
    
    # Service function groups
    ./services/group.nix
    ./downloads/group.nix
    ./transcoding/group.nix
    ./cleanup/group.nix
  ];
}