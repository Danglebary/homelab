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

    nft = "${pkgs.nftables}/bin/nft";
    ip  = "${pkgs.iproute2}/bin/ip";
in
{
    #### Kernel / sysctl ####
    boot.kernelModules = [ "tun" ];

    boot.kernel.sysctl = {
    "net.ipv4.conf.all.src_valid_mark" = 1;
    };

    #### OpenVPN service ####
    systemd.services.openvpn-pia = {
    description = "OpenVPN connection to PIA (Seattle)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
        Type = "notify";
        PrivateTmp = true;
        WorkingDirectory = "/etc/openvpn/pia";

        ExecStart = ''
        ${pkgs.openvpn}/bin/openvpn \
            --dev tun0 \
            --config /etc/openvpn/pia/pia.conf \
            --auth-user-pass /etc/openvpn/pia/credentials.txt
        '';

        ExecStartPost = pkgs.writeShellScript "vpn-routing-setup" ''
        # Default route via VPN in table 100
        ${ip} route replace default dev tun0 table ${toString vpnTableNumber}

        # Policy routing per UID
        ${lib.concatStringsSep "\n" (map (uid:
            "${ip} rule replace uidrange ${toString uid}-${toString uid} lookup ${toString vpnTableNumber}"
        ) vpnUIDs)}
        '';

        ExecStopPost = pkgs.writeShellScript "vpn-routing-cleanup" ''
        # Flush VPN routing table
        ${ip} route flush table ${toString vpnTableNumber} 2>/dev/null || true
        '';

        Restart = "on-failure";
        RestartSec = "10s";

        AmbientCapabilities = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
        ];
    };
    };

    #### nftables kill switch ####
    networking.nftables.enable = true;

    systemd.services.vpn-killswitch = {
        description = "Per-UID VPN kill switch";
        after  = [ "network-online.target" "openvpn-pia.service" ];
        wants  = [ "network-online.target" "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;

            ExecStart = pkgs.writeShellScript "vpn-killswitch" ''
            nft="${pkgs.nftables}/bin/nft"

            # Create table and chain
            $nft add table inet vpnkill || true
            $nft flush table inet vpnkill
            $nft add chain inet vpnkill output '{ type filter hook output priority -100; policy accept; }'

            # Runtime list of VPN users
            for user in deluge sonarr radarr prowlarr; do
                uid=$(id -u "$user" 2>/dev/null || continue)

                # Allow loopback
                $nft add rule inet vpnkill output meta skuid $uid oifname "lo" accept

                # Block DNS outside tun0
                $nft add rule inet vpnkill output meta skuid $uid ip protocol udp udp dport 53 oifname != "tun0" drop
                $nft add rule inet vpnkill output meta skuid $uid ip protocol tcp tcp dport 53 oifname != "tun0" drop

                # Drop all other traffic outside tun0
                $nft add rule inet vpnkill output meta skuid $uid oifname != "tun0" drop
            done
            '';

            ExecStop = ''
            ${pkgs.nftables}/bin/nft delete table inet vpnkill 2>/dev/null || true
            '';
        };
    };


    #### Optional but strongly recommended (prevent IPv6 leaks) ####
    networking.enableIPv6 = false;
}
