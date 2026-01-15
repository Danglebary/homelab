{ config, lib, pkgs, ... }:

{
    systemd.services.plex = {
        description = "Plex Media Server";

        # Ensure the service starts after network is up
        after    = [ "network-online.target" ];
        wants    = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "plex";
            Group = "services";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/plex";
            ReadWritePaths   = [ "/var/lib/services/plex" ];
            ReadOnlyPaths    = [ "/mnt/vault/media" ];

            ExecStart = "${pkgs.plex}/bin/plexmediaserver";
            Environment = [
                "PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/var/lib/services/plex"
                "PLEX_MEDIA_SERVER_HOME=${pkgs.plex}/lib/plexmediaserver"
                "TZ=America/Los_Angeles"
                "LD_LIBRARY_PATH="
            ];

            # Security settings
            RestrictRealtime = true;
            # RestrictSUIDSGID = true;
            # NoNewPrivileges  = true;
            # LockPersonality  = true;
            # ProtectSystem    = "strict";
            # ProtectHome      = true;
            # PrivateTmp       = true;

            # Restrict network access to only necessary address families
            # RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];

            # Allow access to GPU devices for hardware transcoding
            DeviceAllow = [
                "/dev/dri/renderD128 rw"  # Intel/AMD GPU
                "/dev/dri/card0 rw"       # GPU card
            ];

            # Restart on failure
            Restart    = "on-failure";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "300s"; # Allow up to 5 minutes to shut down
        };
    };
}
