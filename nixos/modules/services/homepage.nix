{ config, lib, pkgs, ... }:

{
    systemd.services.homepage = {
        description = "Homepage Dashboard";

        # Ensure the service starts after network is up
        after    = [ "network-online.target" ];
        wants    = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "homepage";
            Group = "services";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/homepage";
            ReadWritePaths   = [ "/var/lib/services/homepage" ];
            CacheDirectory   = "homepage-dashboard";

            # Homepage environment variables
            Environment = [
                "TZ=America/Los_Angeles"
                "PORT=3000"
                "HOMEPAGE_CONFIG_DIR=/var/lib/services/homepage"
                "HOMEPAGE_PUBLIC_DIR=/var/lib/services/homepage/public"
                "HOMEPAGE_ALLOWED_HOSTS=localhost:3000,127.0.0.1:3000,192.168.68.100:3000,homelab-hl15.local:3000"
            ];

            ExecStart = "${pkgs.homepage-dashboard}/bin/homepage";

            # Security settings
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            NoNewPrivileges  = true;
            LockPersonality  = true;
            ProtectSystem    = "strict";
            ProtectHome      = true;
            PrivateTmp       = true;

            # Restrict network access to only necessary address families
            RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];

            # Restart on failure
            Restart    = "on-failure";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "120s"; # Allow up to 2 minutes to shut down
        };
    };
}
