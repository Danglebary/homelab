# Network Configuration Module
# Imports all network-related configurations including global settings and service-specific rules

{ config, lib, pkgs, ... }:

{
  imports = [
    # Service-specific network configurations
    ./immich.nix
  ];

  # Global network configuration
  
  # Set our hostname
  networking.hostName = "homelab-hl15";
  
  # Required for ZFS - unique identifier for this machine
  networking.hostId = "8425e349";

  # Disable NetworkManager in favor of networkd
  networking.useNetworkd = true;
  networking.networkmanager.enable = false;

  # Override DHCP settings from hardware-configuration.nix
  networking.useDHCP = false;

  # Firewall configuration
  networking.firewall = {
    # Allow inbound TCP ports
    allowedTCPPorts = [
      22    # SSH
      2283  # Immich
    ];

    # Trust Docker interfaces (rootless Docker uses slirp4netns)
    # This allows Docker containers to make outbound connections
    trustedInterfaces = [ "docker0" "br-+" ];

    # Allow forwarding for Docker (required for container networking)
    extraCommands = ''
      # Allow Docker containers to access the internet
      iptables -A FORWARD -i docker+ -j ACCEPT
      iptables -A FORWARD -o docker+ -j ACCEPT
    '';
  };

  # Enable networking
  systemd.network.enable = true;

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
      dns = [ "192.168.68.1" ];
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