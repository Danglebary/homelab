# Group Modules - Auto-Discovery
# Imports all group definitions for homelab services

{ config, lib, pkgs, ... }:

{
  imports = [
    # Single consolidated service group
    ./services/group.nix
  ];
}