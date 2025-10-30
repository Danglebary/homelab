{ config, lib, pkgs, ... }:

{
    # Global network configuration

    # Enable networking
    systemd.network.enable = true;
  
    # Set our hostname
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
        # Allow inbound TCP ports (SSH only - services managed in ./service-name.nix)
        allowedTCPPorts = [
            22    # SSH
            2283  # Immich
            32400 # Plex
        ];

        # Trust Docker bridge interfaces for container networking
        trustedInterfaces = [ "docker0" "br-+" ];

        # Allow traffic forwarding for Docker containers
        # Required for containers to reach internet and for inter-container communication
        extraCommands = ''
            iptables -A FORWARD -i docker+ -j ACCEPT
            iptables -A FORWARD -o docker+ -j ACCEPT
        '';
    };

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

    systemd.network.networks = {
        "10-bond0" = {
            matchConfig.Name = "bond0";
            address = [ "192.168.68.100/24" ];
            gateway = [ "192.168.68.1" ];

            # DNS configuration - must be in networkConfig for systemd-networkd
            networkConfig = {
                DNS = "192.168.68.1 1.1.1.1 1.0.0.1";
            };
        };

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