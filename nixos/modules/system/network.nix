{ config, lib, pkgs, ... }:

{
    # Open firewall port for Immich web interface and API
    networking.firewall.allowedTCPPorts = [ 2283 ];
}