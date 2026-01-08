{ config, lib, pkgs, ... }:

{
    systemd.services.deluge = {
        description = "Deluge Bittorrent Client Daemon";

        # Ensure the service starts after network and VPN is up
        after = [
            "network-online.target"
            "openvpn-pia.service"
        ];
        wants = [
            "network-online.target"
            "openvpn-pia.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User = "deluge";
            Group = "services";
            Slice = "vpn.slice";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/deluge";
            ReadWritePaths = [
                /var/lib/services/deluge
                /mnt/vault/downloads
            ];

            ExecStart   = "${pkgs.deluge}/bin/deluged -c /var/lib/services/deluge";
            Environment = [ "TZ=America/Los_Angeles" ];
            
            # Security settings
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            NoNewPrivileges  = true;
            LockPersonality  = true;
            ProtectSystem    = "strict";
            ProtectHome      = true;
            PrivateTmp       = true;

            # Restrict network access to only necessary address families
            RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

            # Restart on failure
            Restart    = "on-failure";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "300s"; # Allow up to 5 minutes to shut down
        };
    };
}