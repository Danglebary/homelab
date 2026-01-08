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
        ${pkgs.iproute2}/bin/ip route replace default dev tun0 table ${toString vpnTableNumber}

        # Policy routing per UID
        ${lib.concatStringsSep "\n" (map (uid:
            "${pkgs.iproute2}/bin/ip rule replace uidrange ${toString uid}-${toString uid} lookup ${toString vpnTableNumber}"
        ) vpnUIDs)}
        '';

        ExecStopPost = pkgs.writeShellScript "vpn-routing-cleanup" ''
        # Remove UID routing rules
        ${lib.concatStringsSep "\n" (map (uid:
            "${pkgs.iproute2}/bin/ip rule del uidrange ${toString uid}-${toString uid} lookup ${toString vpnTableNumber} 2>/dev/null || true"
        ) vpnUIDs)}

        # Flush VPN routing table
        ${pkgs.iproute2}/bin/ip route flush table ${toString vpnTableNumber} 2>/dev/null || true
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
            ${pkgs.nftables}/bin/nft add table inet vpnkill || true
            ${pkgs.nftables}/bin/nft flush table inet vpnkill

            ${pkgs.nftables}/bin/nft add chain inet vpnkill output \
                '{ type filter hook output priority -100; policy accept; }'

            ${lib.concatStringsSep "\n" (map (uid: ''
                ${pkgs.nftables}/bin/nft add rule inet vpnkill output skuid ${toString uid} oifname "lo" accept
                ${pkgs.nftables}/bin/nft add rule inet vpnkill output skuid ${toString uid} udp dport 53 oifname != "tun0" drop
                ${pkgs.nftables}/bin/nft add rule inet vpnkill output skuid ${toString uid} tcp dport 53 oifname != "tun0" drop
                ${pkgs.nftables}/bin/nft add rule inet vpnkill output skuid ${toString uid} oifname != "tun0" drop
            '') vpnUIDs)}
            '';

            ExecStop = ''
            ${pkgs.nftables}/bin/nft delete table inet vpnkill 2>/dev/null || true
            '';
        };
    };

    #### Optional but strongly recommended (prevent IPv6 leaks) ####
    networking.enableIPv6 = false;
}
