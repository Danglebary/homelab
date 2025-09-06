# System Modules - Auto-Discovery
# Imports all system-level configurations including directories and networking

{ config, lib, pkgs, ... }:

{
  imports = [
    # Service-specific system configurations
    ./directories
    ./network
    ./services
    
    # Future system modules can be added here:
    # ./directories  # When we have more directory modules
    # ./security     # For security policies
  ];
}