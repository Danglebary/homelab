{ config, lib, pkgs, ... }:

{
    systemd.services.overseerr = {
        description = "Overseerr Media Request Management";

        # Ensure the service starts after network is up
        after    = [ "network-online.target" ];
        wants    = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "overseerr";
            Group = "services";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/overseerr";
            ReadWritePaths   = [ "/var/lib/services/overseerr" ];

            # Overseerr environment variables
            Environment = [ "TZ=America/Los_Angeles" ];

            ExecStart = "${pkgs.overseerr}/bin/overseerr";

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
