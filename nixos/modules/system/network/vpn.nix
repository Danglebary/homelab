{ config, lib, pkgs, ... }:

let
  vpnUsers = [
    "deluge"
    "sonarr"
    "radarr"
    "prowlarr"
  ];

  # Convert VPN users to UIDs
  vpnUIDs = map (u: config.users.users.${u}.uid) vpnUsers;

  vpnTableNumber = 100;
in
{
    # Load TUN/TAP kernel module for VPN support
    boot.kernelModules = [ "tun" ];

    # Ensure /dev/net/tun is available
    boot.kernel.sysctl = {
        "net.ipv4.conf.all.src_valid_mark" = 1;
    };

    # OpenVPN service for PIA (Private Internet Access)
    systemd.services.openvpn-pia = {
        description = "OpenVPN connection to PIA (Seattle)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            Type = "notify";
            PrivateTmp = true;
            WorkingDirectory = "/etc/openvpn/pia";

            # Force interface name to tun0 to prevent race conditions
            ExecStart = "${pkgs.openvpn}/bin/openvpn --dev tun0 --config /etc/openvpn/pia/pia.conf --auth-user-pass /etc/openvpn/pia/credentials.txt";

            # Configure VPN routing after tunnel is established
            ExecStartPost = pkgs.writeShellScript "vpn-routing-setup" ''
                # Add default route via VPN table
                ${pkgs.iproute2}/bin/ip route add default dev tun0 table vpn || true

                # Add policy routing rules for each VPN service user
                ${lib.concatStringsSep "\n" (map (uid:
                    "${pkgs.iproute2}/bin/ip rule add uidrange ${toString uid}-${toString uid} lookup vpn || true"
                ) vpnUIDs)}

                echo "VPN routing configured successfully"
            '';

            # Clean up routing rules when service stops
            ExecStopPost = pkgs.writeShellScript "vpn-routing-cleanup" ''
                # Remove policy routing rules
                ${lib.concatStringsSep "\n" (map (uid:
                    "${pkgs.iproute2}/bin/ip rule del uidrange ${toString uid}-${toString uid} lookup vpn 2>/dev/null || true"
                ) vpnUIDs)}

                # Remove VPN routes
                ${pkgs.iproute2}/bin/ip route flush table vpn 2>/dev/null || true

                echo "VPN routing cleaned up"
            '';

            Restart = "on-failure";
            RestartSec = "10s";

            # OpenVPN needs these capabilities for network setup
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
        };
    };

    # Define custom routing table for VPN
    networking.iproute2 = {
        enable = true;
        tables = {
            vpn = 100;
        };
    };


    # VPN kill switch - prevents traffic leaks if VPN goes down
    networking.firewall.extraCommands = lib.concatStringsSep "\n" (
        [
            "# Create vpnkill table and chain with higher priority"
            "nft add table inet vpnkill || true"
            "nft flush table inet vpnkill || true"
            "nft add chain inet vpnkill output { type filter hook output priority -100\\; policy accept\\; } || true"

            "# Allow loopback traffic for VPN users"
        ]
        ++ (map (uid: "nft add rule inet vpnkill output skuid ${toString uid} oifname \\\"lo\\\" accept || true") vpnUIDs)
        ++ [
            ""
            "# Prevent DNS leaks - block DNS traffic not going through tun0"
        ]
        ++ (map (uid: "nft add rule inet vpnkill output skuid ${toString uid} udp dport 53 oifname != \\\"tun0\\\" drop || true") vpnUIDs)
        ++ (map (uid: "nft add rule inet vpnkill output skuid ${toString uid} tcp dport 53 oifname != \\\"tun0\\\" drop || true") vpnUIDs)
        ++ [
            ""
            "# Drop all other traffic from VPN users not going through tun0"
        ]
        ++ (map (uid: "nft add rule inet vpnkill output skuid ${toString uid} oifname != \\\"tun0\\\" drop || true") vpnUIDs)
    );

    # Clean up kill switch on firewall stop
    networking.firewall.extraStopCommands = ''
        nft delete table inet vpnkill 2>/dev/null || true
    '';
}