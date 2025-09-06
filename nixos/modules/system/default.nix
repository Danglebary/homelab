# System Modules - Auto-Discovery
# Imports all system-level configurations including directories and networking

{ config, lib, pkgs, ... }:

{
  imports = [
    # Service-specific system configurations
    ./directories/immich.nix
    ./network
    ./services/cloudflared.nix
    
    # Future system modules can be added here:
    # ./directories  # When we have more directory modules
    # ./security     # For security policies
  ];
}