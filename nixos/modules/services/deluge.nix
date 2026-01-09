{ config, lib, pkgs, ... }:

{
    # Port forwarding from host to VPN namespace for Deluge web UI
    networking.nftables.ruleset = ''
      table inet nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          # Forward Deluge web UI port to VPN namespace
          tcp dport 8112 dnat to 10.200.200.2
        }
      }
    '';

    systemd.services.deluge = {
        description = "Deluge Bittorrent Client Daemon";

        # Ensure the service starts after VPN is up and bind lifecycle
        after = [ "openvpn-pia.service" ];
        requires = [ "openvpn-pia.service" ];
        bindsTo = [ "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User = "deluge";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/deluge";
            ReadWritePaths = [
                /var/lib/services/deluge
                /mnt/vault/downloads
            ];

            ExecStart   = "${pkgs.deluge}/bin/deluged -d -c /var/lib/services/deluge";
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

    systemd.services.deluge-web = {
        description = "Deluge Web UI";

        # Ensure the service starts after deluged and VPN is up
        after = [ "deluge.service" "openvpn-pia.service" ];
        requires = [ "deluge.service" "openvpn-pia.service" ];
        bindsTo = [ "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
            # Identity
            User = "deluge";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/deluge";
            ReadWritePaths = [ /var/lib/services/deluge ];

            ExecStart = "${pkgs.deluge}/bin/deluge-web -d -c /var/lib/services/deluge";
            Environment = [ "TZ=America/Los_Angeles" ];

            # Security settings
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            NoNewPrivileges = true;
            LockPersonality = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;

            # Restrict network access to only necessary address families
            RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

            # Restart on failure
            Restart = "on-failure";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "120s";
        };
    };
}