# Cloudflared Tunnel Service Configuration
# Manages Cloudflare Zero Trust tunnel for remote access

{ config, lib, pkgs, ... }:

{
    # Enable cloudflared tunnel service
    systemd.services.cloudflared-tunnel = {
        description = "Cloudflare Tunnel";

        # Ensure the service starts after network is fully online
        after    = [ "network-online.target" ];
        wants    = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "cloudflared";
            Group = "services";
            Type  = "simple";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/cloudflared";
            ReadWritePaths   = [ "/var/lib/services/cloudflared" ];

            ExecStart   = "${pkgs.cloudflared}/bin/cloudflared tunnel run --config /etc/cloudflared/config.yml";
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
            RestartSec = "10s";

            # Graceful shutdown
            TimeoutStopSec = "30s";
        };
    };

    environment.etc."cloudflared/config.yml".text = ''
        tunnel: 3e469ec3-0aca-4d25-9908-dd90f0538037
        credentials-file: /var/lib/services/cloudflared/credentials.json

        ingress:
            - hostname: requests.halfblown.dev
              service: http://localhost:5055
            - service: http_status:404
    '';
}