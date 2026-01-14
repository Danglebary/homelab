{ config, lib, pkgs, ... }:

{
    # Port forwarding from host to VPN namespace for Prowlarr web UI
    networking.nftables.ruleset = ''
      table inet nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          # Forward Prowlarr web UI port to VPN namespace
          tcp dport 9696 dnat ip to 10.200.200.2
        }
      }
    '';

    systemd.services.prowlarr = {
        description = "Prowlarr Indexer Manager";

        # Ensure the service starts after VPN is up
        after = [ "openvpn-pia.service" "flaresolverr.service" ];
        wants = [ "openvpn-pia.service" "flaresolverr.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User  = "prowlarr";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/prowlarr";
            ReadWritePaths = [
                /var/lib/services/prowlarr
            ];

            ExecStart   = "${pkgs.prowlarr}/bin/Prowlarr -nobrowser --data=/var/lib/services/prowlarr";
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