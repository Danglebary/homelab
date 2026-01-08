{ config, lib, pkgs, ... }:

{
    systemd.services.prowlarr = {
        description = "Prowlarr Indexer Manager";

        # Ensure the service starts after network and VPN is up
        after = [
            "network-online.target"
            "wg-quick@wg0.service"
        ];
        wants = [
            "network-online.target"
            "wg-quick@wg0.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "prowlarr";
            Group = "services";
            Slice = "vpn.slice";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/prowlarr";
            ReadWritePaths = [
                /var/lib/services/prowlarr
                /mnt/vault/downloads
            ];

            ExecStart   = "${pkgs.prowlarr}/bin/prowlarr -nobrowser --data=/var/lib/services/prowlarr";
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
            TimeoutStopSec = "120s"; # Allow up to 2 minutes to shut down
        };
    };
}