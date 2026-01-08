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

            Restart = "on-failure";
            RestartSec = "10s";

            # OpenVPN needs these capabilities for network setup
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
        };
    };

    # VPN routing setup service (handles routing table creation and policy routing)
    systemd.services.vpn-routing = {
        description = "VPN slice routing for homelab services";
        after = [ "network.target" "openvpn-pia.service" ];
        requires = [ "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];
        # Bind lifecycle to OpenVPN - if OpenVPN stops, this stops too
        bindsTo = [ "openvpn-pia.service" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Wait for tun0 to exist before starting
            ExecStartPre = pkgs.writeShellScript "wait-for-tun0" ''
                echo "Waiting for tun0 interface to be created by OpenVPN..."
                for i in {1..60}; do
                    if ${pkgs.iproute2}/bin/ip link show tun0 &>/dev/null; then
                        echo "tun0 interface found"
                        # Also verify it's in UP state
                        if ${pkgs.iproute2}/bin/ip link show tun0 | grep -q "state UP"; then
                            echo "tun0 is UP and ready"
                            exit 0
                        else
                            echo "tun0 exists but not UP yet, waiting..."
                        fi
                    fi
                    if [ $i -eq 60 ]; then
                        echo "ERROR: tun0 did not appear or come UP after 60 seconds"
                        echo "OpenVPN service status:"
                        ${pkgs.systemd}/bin/systemctl status openvpn-pia.service || true
                        exit 1
                    fi
                    sleep 1
                done
            '';
            ExecStart = pkgs.writeShellScript "vpn-routing-setup" ''

                # Add VPN routing table if it doesn't exist
                grep -q '^${toString vpnTableNumber} vpn$' /etc/iproute2/rt_tables || \
                    echo '${toString vpnTableNumber} vpn' >> /etc/iproute2/rt_tables

                # Add default route via VPN table
                ip route add default dev tun0 table vpn || true

                # Add policy routing rules for each VPN service user
                ${lib.concatStringsSep "\n" (map (uid:
                    "ip rule add uidrange ${toString uid}-${toString uid} lookup vpn || true"
                ) vpnUIDs)}

                echo "VPN routing configured successfully"
            '';
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