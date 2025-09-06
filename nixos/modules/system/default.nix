# System Modules - Auto-Discovery
# Imports all system-level configurations including directories and networking

{ config, lib, pkgs, ... }:

{
  imports = [
    # Service-specific system configurations
    ./directories/immich.nix
    ./network
    
    # Future system modules can be added here:
    # ./directories  # When we have more directory modules
    # ./services     # For systemd service definitions
    # ./security     # For security policies
  ];
}