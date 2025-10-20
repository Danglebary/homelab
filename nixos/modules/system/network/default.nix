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

  # Disable systemd-resolved (causes Docker DNS issues)
  # Use static DNS configuration instead
  services.resolved.enable = false;

  # Set static DNS servers for the system
  networking.nameservers = [ "192.168.68.1" "1.1.1.1" "1.0.0.1" ];

  # Override DHCP settings from hardware-configuration.nix
  networking.useDHCP = false;

  # Firewall configuration
  networking.firewall = {
    # Allow inbound TCP ports (SSH only - services managed in ./service-name.nix)
    allowedTCPPorts = [
      22    # SSH
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