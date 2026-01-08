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
            ExecStart = "${pkgs.openvpn}/bin/openvpn --config /etc/openvpn/pia/pia.conf --auth-user-pass /etc/openvpn/pia/credentials.txt";

            Restart = "on-failure";
            RestartSec = "10s";

            # OpenVPN needs these capabilities for network setup
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_SETUID" "CAP_SETGID" ];
        };
    };

    # Dedicated routing table for VPN slice
    networking.extraCommands = lib.concatStringsSep "\n" [
        # Only add the table if it doesn't exist yet
        "grep -q '^${toString vpnTableNumber} vpn\$' /etc/iproute2/rt_tables || echo '${toString vpnTableNumber} vpn' >> /etc/iproute2/rt_tables"

        # Add default route via tun0 for vpn table
        "ip route add default dev tun0 table vpn || true"

        # Add policy routing rules for each VPN service user
        (lib.concatStringsSep "\n" (map (uid: "ip rule add uidrange ${toString uid}-${toString uid} lookup vpn || true") vpnUIDs))
    ];

    # Ensure VPN routing rules are applied on boot
    systemd.services.vpn-routing = {
        description = "VPN slice routing for homelab services";
        after = [ "network.target" "openvpn-pia.service" ];
        wants = [ "network.target" "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.concatStringsSep " && " [
                # Default route via VPN table
                "ip route add default dev tun0 table vpn || true"
                # Policy routing for VPN slice UIDs
                (lib.concatStringsSep " && " (map (uid: "ip rule add uidrange ${toString uid}-${toString uid} lookup vpn || true") vpnUIDs))
            ];
        };
    };

    # Ensure VPN traffic is dropped if the VPN goes down (kill switch)
    networking.firewall.extraCommands = lib.concatStringsSep "\n" (
        [
            "# Drop all outgoing traffic from VPN slice if tun0 is down"
            "nft add table inet vpnkill || true"
            "nft add chain inet vpnkill output { type filter hook output priority 0; policy accept; } || true"
        ]
        ++ (map (uid: "nft add rule inet vpnkill output skuid ${toString uid} oifname != \\\"tun0\\\" drop || true") vpnUIDs)
    );
}