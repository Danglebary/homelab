{ config, lib, pkgs, ... }:

{
    # Port forwarding from host to VPN namespace for Deluge web UI
    networking.nftables.ruleset = ''
      table inet nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          # Forward Deluge web UI port to VPN namespace
          tcp dport 8112 dnat ip to 10.200.200.2
        }
      }
    '';

    systemd.services.deluge = {
        description = "Deluge Bittorrent Client Daemon";

        # Ensure the service starts after VPN is up
        after = [ "openvpn-pia.service" ];
        requires = [ "openvpn-pia.service" ];
        wantedBy = [ "multi-user.target" ];

        # Set PATH to include deluge and extraction utilities (needed for plugins)
        path = [ pkgs.deluge pkgs.unzip pkgs.gnutar pkgs.xz pkgs.bzip2 ];

        serviceConfig = {
            # Identity
            User = "deluge";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";

            # Network capabilities (not actually required - AF_NETLINK was the real fix)
            # AmbientCapabilities = [ "CAP_NET_ADMIN" ];
            # CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/deluge";
            ReadWritePaths = [
                /var/lib/services/deluge
                /mnt/vault/downloads
            ];

            ExecStart   = "${pkgs.deluge}/bin/deluged -d -L debug --do-not-daemonize --config /var/lib/services/deluge";
            Environment = [ "TZ=America/Los_Angeles" ];

            # Security settings
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            NoNewPrivileges  = true;
            LockPersonality  = true;
            ProtectSystem    = "strict";
            ProtectHome      = true;
            PrivateTmp       = true;

            # Restrict network access to necessary address families
            # AF_NETLINK required for libtorrent's interface enumeration
            # AF_INET6 removed since VPN namespace has IPv6 disabled
            RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" "AF_NETLINK" ];

            # Restart always (including when VPN restarts)
            Restart    = "always";
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
        wantedBy = [ "multi-user.target" ];

        # Set PATH to include deluge
        path = [ pkgs.deluge ];

        serviceConfig = {
            # Identity
            User = "deluge";
            Group = "services";

            # Run in VPN network namespace (all traffic forced through VPN)
            NetworkNamespacePath = "/var/run/netns/vpn";

            # Paths that the service can read and write
            WorkingDirectory = "/var/lib/services/deluge";
            ReadWritePaths = [ /var/lib/services/deluge ];

            ExecStart = "${pkgs.deluge}/bin/deluge-web --do-not-daemonize --config /var/lib/services/deluge";
            Environment = [ "TZ=America/Los_Angeles" ];

            # Security settings
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            NoNewPrivileges = true;
            LockPersonality = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;

            # Restrict network access to only necessary address families (IPv4 only, VPN namespace has IPv6 disabled)
            RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];

            # Restart always (including when VPN restarts)
            Restart = "always";
            RestartSec = "5s";

            # Graceful shutdown
            TimeoutStopSec = "120s";
        };
    };
}