{ config, lib, pkgs, ... }:

{
    # Port forwarding from host to VPN namespace for Sonarr web UI
    networking.nftables.ruleset = ''
      table inet nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          # Forward Sonarr web UI port to VPN namespace
          tcp dport 8989 dnat ip to 10.200.200.2
        }
      }
    '';

    systemd.services.sonarr = {
        description = "Sonarr TV Show Manager";

        # Ensure the service starts after VPN is up
        after = [ "wg-proton.service" "prowlarr.service" ];
        wants = [ "wg-proton.service" "prowlarr.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "sonarr";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/sonarr";
            ReadWritePaths = [
                /var/lib/services/sonarr
                /mnt/vault/media/shows
                /mnt/vault/media/anime
                /mnt/vault/downloads
            ];

            ExecStart   = "${pkgs.sonarr}/bin/Sonarr -nobrowser --data=/var/lib/services/sonarr";
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
            RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];

            # Restart always (including when VPN restarts)
            Restart    = "always";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "120s"; # Allow up to 2 minutes to shut down
        };
    };
}