# NixOS Modules - Homelab Configuration
# Auto-discovery of groups, users, and system configurations

{ config, lib, pkgs, ... }:

{
  imports = [
    # User accounts and groups
    ./groups
    ./users/admin.nix
    ./users/dev.nix
    ./users/halfblown.nix
    ./users/service.nix

    # System-level configurations
    ./system
  ];
}