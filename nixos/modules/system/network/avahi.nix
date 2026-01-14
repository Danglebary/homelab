{ config, lib, pkgs, ... }:

{
    # Enable Avahi for mDNS (Multicast DNS) resolution
    # Allows the server to be accessed via homelab-hl15.local on the network
    services.avahi = {
        enable = true;

        # Enable NSS mDNS support for hostname resolution
        nssmdns4 = true;  # IPv4 mDNS resolution

        # Publish server information on the network
        publish = {
            enable = true;
            addresses = true;      # Publish IP addresses
            domain = true;         # Publish domain information
            workstation = true;    # Announce as a workstation
        };

        # Allow network interfaces
        # By default, Avahi publishes on all interfaces
        # Can be restricted if needed: allowInterfaces = [ "bond0" ];
    };

    # Open firewall for mDNS (UDP port 5353)
    networking.firewall.allowedUDPPorts = [ 5353 ];
}
