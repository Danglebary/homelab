# Immich Network Configuration
# Opens required firewall ports for Immich photo management service
# Service accessible on port 2283 for web interface and API

{ config, lib, pkgs, ... }:

{
  # Open firewall port for Immich web interface and API
  networking.firewall.allowedTCPPorts = [ 2283 ];
}