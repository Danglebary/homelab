{ config, lib, pkgs, ... }:

{
    imports = [
        ./cloudflared.nix
        ./nfs.nix
        ./ssh.nix
        ./vpn.nix
    ];

    # Global networking configuration

    # Enable networking
    systemd.network.enable = true;

    # Set the hostname
    networking.hostName = "homelab-hl15";

    # Required for ZFS - unique identifier for this machine
    networking.hostId = "8425e349";

    # Disable NetworkManager in favor of networkd
    networking.useNetworkd = true;
    networking.networkmanager.enable = false;

    # Enable systemd-resolved for proper DNS with systemd-networkd
    services.resolved = {
        enable = true;
        # Disable LLMNR and mDNS (not needed for server)
        llmnr = "false";
        extraConfig = ''
            MulticastDNS=false
        '';
        # Fallback DNS servers if network config DNS fails
        fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
    };

    # Override DHCP settings from hardware-configuration.nix
    networking.useDHCP = false;

    # Firewall configuration
    networking.firewall = {
        enable = true;

        # Allow inbound TCP ports
        allowedTCPPorts = [
            22    # SSH
            32400 # Plex
        ];
    };

    # Bonded network interface configuration
    systemd.network.netdevs."10-bond0" = {
        netdevConfig = {
            Name = "bond0";
            Kind = "bond";
        };

        bondConfig = {
            Mode = "802.3ad"; # LACP
            LACPTransmitRate = "fast";
            TransmitHashPolicy = "layer3+4";
        };
    };

    # Define network interfaces and bonding
    systemd.network.networks = {
        # Bonded interface with static IP
        "10-bond0" = {
            matchConfig.Name = "bond0";
            address = [ "192.168.68.100/24" ];
            gateway = [ "192.168.68.1" ];

            # DNS configuration - must be in networkConfig for systemd-networkd
            networkConfig = {
                DNS = "192.168.68.1 1.1.1.1 1.0.0.1";
            };
        };

        # Physical interfaces part of the bond

        "20-eno1" = {
            matchConfig.Name = "eno1";
            networkConfig = {
                Bond = "bond0";
                DHCP = "no";
            };
        };

        "21-eno2" = {
            matchConfig.Name = "eno2";
            networkConfig = {
                Bond = "bond0";
                DHCP = "no";
            };
        };
    };
}