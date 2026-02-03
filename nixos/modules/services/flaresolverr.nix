{ config, lib, pkgs, ... }:

{
    systemd.services.flaresolverr = {
        description = "FlareSolverr - Cloudflare Solver Proxy";

        # Ensure the service starts after VPN is up
        after = [ "wg-proton.service" ];
        wants = [ "wg-proton.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "flaresolverr";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";
            BindReadOnlyPaths = [ "/etc/netns/vpn/resolv.conf:/etc/resolv.conf" ];

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/flaresolverr";
            ReadWritePaths = [
                /var/lib/services/flaresolverr
            ];

            ExecStart = "${pkgs.flaresolverr}/bin/flaresolverr";
            Environment = [
                "TZ=America/Los_Angeles"
                "PORT=8191"
                "LOG_LEVEL=info"
            ];

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

            # Restart always (including when VPN restarts)
            Restart    = "always";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "30s";
        };
    };
}
