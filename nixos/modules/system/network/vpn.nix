{ config, lib, pkgs, ... }:

let
  namespaceName = "vpn";

  # veth pair interface names
  vethHost = "veth-vpn-h";   # Host side
  vethNS = "veth-vpn-ns";    # Namespace side

  # IP addresses for the veth pair (using /30 for point-to-point link)
  hostIP = "10.200.200.1";
  nsIP = "10.200.200.2";
  vethSubnet = "10.200.200.0/30";

  # RFC1918 private IP ranges for LAN routing
  privateLANRanges = [
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
  ];

  ip = "${pkgs.iproute2}/bin/ip";
  mount = "${pkgs.util-linux}/bin/mount";
  umount = "${pkgs.util-linux}/bin/umount";
  sysctl = "${pkgs.procps}/bin/sysctl";
in
{
  # Load TUN/TAP kernel module for VPN support
  boot.kernelModules = [ "tun" ];

  # Enable IP forwarding for routing between namespace and host
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Network namespace template service
  # Creates isolated network environments with veth pair for host connectivity
  # Keeps running to maintain the namespace for other services to join
  systemd.services."netns@" = {
    description = "Named network namespace %I with veth pair";
    before = [ "network-pre.target" ];
    serviceConfig = {
      Type = "simple";

      # Create isolated network namespace
      PrivateNetwork = true;

      # Required capabilities for network namespace and network operations
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_SYS_ADMIN" ];

      ExecStartPre = let
        script = pkgs.writeShellScript "netns-setup" ''
          set -e

          # Create veth pair to bridge namespace with host
          ${ip} link add ${vethHost} type veth peer name ${vethNS}

          # Move namespace-side veth into this service's namespace
          ${ip} link set ${vethNS} netns $BASHPID

          # Configure host-side veth interface
          ${ip} addr add ${hostIP}/30 dev ${vethHost}
          ${ip} link set ${vethHost} up
        '';
      in "${script}";

      ExecStart = pkgs.writeShellScript "netns-run" ''
        set -e

        # Configure namespace-side veth interface
        ${ip} addr add ${nsIP}/30 dev ${vethNS}
        ${ip} link set ${vethNS} up
        ${ip} link set lo up

        # Disable IPv6 inside namespace to prevent IPv6 leaks
        ${sysctl} -w net.ipv6.conf.all.disable_ipv6=1
        ${sysctl} -w net.ipv6.conf.default.disable_ipv6=1

        # Add kill-switch: blackhole route as fallback if VPN drops
        # This has metric 999 so it only applies if the default route via tun0 disappears
        ${ip} route add blackhole 0.0.0.0/0 metric 999

        # Add routes to direct LAN traffic through veth
        # (Internet traffic will use default route through tun0 set by OpenVPN)
        # These routes are more specific than the blackhole, so they take precedence
        ${lib.concatMapStringsSep "\n" (range:
          "${ip} route add ${range} via ${hostIP} dev ${vethNS}"
        ) privateLANRanges}

        # Keep the namespace alive by sleeping forever
        exec ${pkgs.coreutils}/bin/sleep infinity
      '';

      # Clean up veth pair on stop
      ExecStopPost = "${ip} link delete ${vethHost} 2>/dev/null || true";

      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # OpenVPN service running inside the VPN namespace
  systemd.services.openvpn-pia = {
    description = "OpenVPN connection to PIA (in network namespace)";
    after = [ "network-online.target" "netns@${namespaceName}.service" ];
    wants = [ "network-online.target" ];
    requires = [ "netns@${namespaceName}.service" ];
    bindsTo = [ "netns@${namespaceName}.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      WorkingDirectory = "/etc/openvpn/pia";

      # Join the VPN namespace
      JoinsNamespaceOf = "netns@${namespaceName}.service";
      PrivateNetwork = true;

      # OpenVPN will create tun0 inside the namespace
      ExecStart = "${pkgs.openvpn}/bin/openvpn --config /etc/openvpn/pia/pia.conf --auth-user-pass /etc/openvpn/pia/credentials.txt";

      Restart = "always";
      RestartSec = "10s";

      # OpenVPN needs these capabilities for network setup
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
    };
  };

  # nftables firewall rules for NAT and forwarding
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet nat {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          # Masquerade (NAT) traffic from VPN namespace going to LAN
          # This makes traffic from namespace appear to come from the host
          ip saddr ${vethSubnet} oifname != "${vethHost}" masquerade
        }
      }

      table inet filter {
        chain forward {
          type filter hook forward priority filter; policy drop;

          # Allow established/related connections (stateful firewall)
          ct state { established, related } accept

          # Allow forwarding traffic to/from the VPN namespace veth
          iifname "${vethHost}" accept
          oifname "${vethHost}" accept
        }
      }
    '';
  };
}

# To configure a service to use this VPN namespace, use JoinsNamespaceOf:
#
#   systemd.services.<service-name> = {
#     after = [ "openvpn-pia.service" ];
#     requires = [ "openvpn-pia.service" ];
#     bindsTo = [ "openvpn-pia.service" ];
#     serviceConfig = {
#       JoinsNamespaceOf = "netns@vpn.service";
#       PrivateNetwork = true;
#       # ... other service config ...
#     };
#   };
#
# Services in the VPN namespace will:
#   - Route all internet traffic through the VPN tunnel (tun0)
#   - Route LAN traffic (RFC1918) through the veth pair to access host network
#   - Be accessible from the host/LAN via their service ports
#   - Automatically stop if the VPN connection fails (bindsTo)
#
# Security features:
#   - IPv6 disabled inside namespace (prevents IPv6 leaks)
#   - Blackhole route as kill-switch (drops all internet traffic if VPN drops)
#   - Full network isolation (services cannot access host network interfaces)
#   - Stateful firewall with connection tracking
#
