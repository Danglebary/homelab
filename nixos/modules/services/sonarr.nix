{ config, lib, pkgs, ... }:

{
    systemd.services.sonarr = {
        description = "Sonarr TV Show Manager";

        # Ensure the service starts after VPN is up and bind lifecycle
        after = [ "openvpn-pia.service" ];
        requires = [ "openvpn-pia.service" ];
        bindsTo = [ "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "sonarr";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            JoinsNamespaceOf = "netns@vpn.service";
            PrivateNetwork = true;

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/sonarr";
            ReadWritePaths = [
                /var/lib/services/sonarr
                /mnt/vault/media/shows
                /mnt/vault/media/anime
                /mnt/vault/downloads
            ];

            ExecStart   = "${pkgs.sonarr}/bin/sonarr -nobrowser --data=/var/lib/services/sonarr";
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