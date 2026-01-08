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

    # WireGuard interface configuration (PIA or Private Internet Access)
    networking.wireguard.interfaces.wg0 = {
        enable = true;
        privateKeyFile = "/etc/wireguard/wg0.key";
        address = [ "10.0.0.1/24" ];
        listenPort = 51820;
        table = vpnTableNumber;

        peers = [
            {
                # TODO: Replace with actual peer configuration
                publicKey = "<PIA-server-public-key>";
                allowedIPs = [ "0.0.0.0/0" "::/0" ];
                # TODO: Replace with actual endpoint
                endpoint = "<PIA-server-endpoint>:51820";
                persistentKeepalive = 25;
            }
        ];
    };

    # Dedicated routing table for VPN slice
    networking.extraCommands = lib.concatStringsSep "\n" [
        # Only add the table if it doesn't exist yet
        "grep -q '^${vpnTableNumber} vpn\$' /etc/iproute2/rt_tables || echo '${vpnTableNumber} vpn' >> /etc/iproute2/rt_tables"

        # Add default route via wg0 for vpn table
        "ip route add default dev wg0 table vpn || true"

        # Add policy routing rules for each VPN service user
        (lib.concatStringsSep "\n" (map (uid: "ip rule add uidrange ${uid}-${uid} lookup vpn || true") vpnUIDs))
    ];

    # Ensure VPN routing rules are applied on boot
    systemd.services.vpn-routing = {
        description = "VPN slice routing for homelab services";
        after = [ "network.target" "wg-quick@wg0.service" ];
        wants = [ "network.target" "wg-quick@wg0.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.concatStringsSep " && " [
                # Default route via VPN table
                "ip route add default dev wg0 table vpn || true"
                # Policy routing for VPN slice UIDs
                (lib.concatStringsSep " && " (map (uid: "ip rule add uidrange ${uid}-${uid} lookup vpn || true") vpnUIDs))
            ];
        };
    };

    # Ensure VPN traffic is dropped if the VPN goes down (kill switch)
    networking.firewall.extraCommands = lib.concatStringsSep "\n" [
        "# Drop all outgoing traffic from VPN slice if wg0 is down"
        "nft add table inet vpnkill || true"
        "nft add chain inet vpnkill output { type filter hook output priority 0; policy accept; } || true"
        "nft add rule inet vpnkill oifname != \"wg0\" ip saddr 10.0.0.0/24 drop || true"
    ];
}