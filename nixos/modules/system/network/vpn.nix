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

  # LAN subnet for routing through veth (only the actual LAN, not all of RFC1918,
  # to avoid conflicting with VPN-internal addresses like Proton's 10.2.0.1 DNS)
  privateLANRanges = [
    "192.168.68.0/24"
  ];

  ip = "${pkgs.iproute2}/bin/ip";
  sysctl = "${pkgs.procps}/bin/sysctl";
in
{
  # Enable IP forwarding for routing between namespace and host
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Network namespace template service
  # Creates named network namespaces that persist and can be referenced by other services
  systemd.services."netns@" = {
    description = "Named network namespace %I with veth pair";
    before = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      # Required capabilities for network namespace operations
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_SYS_ADMIN" ];

      ExecStart = let
        script = pkgs.writeShellScript "netns-create" ''
          set -e
          NETNS_NAME="$1"

          # Create persistent network namespace
          ${ip} netns add $NETNS_NAME

          # Create /etc/netns/<name> directory for namespace-specific resolv.conf
          mkdir -p /etc/netns/$NETNS_NAME
          echo "nameserver 10.2.0.1" > /etc/netns/$NETNS_NAME/resolv.conf

          # Create veth pair (both ends start on host)
          ${ip} link add ${vethHost} type veth peer name ${vethNS}

          # Move namespace-side veth INTO the namespace
          ${ip} link set ${vethNS} netns $NETNS_NAME

          # Configure host-side veth (stays on host)
          ${ip} addr add ${hostIP}/30 dev ${vethHost}
          ${ip} link set ${vethHost} up

          # Configure namespace-side veth (inside namespace)
          ${ip} -n $NETNS_NAME addr add ${nsIP}/30 dev ${vethNS}
          ${ip} -n $NETNS_NAME link set ${vethNS} up
          ${ip} -n $NETNS_NAME link set lo up

          # Disable IPv6 inside namespace
          ${ip} netns exec $NETNS_NAME ${sysctl} -w net.ipv6.conf.all.disable_ipv6=1
          ${ip} netns exec $NETNS_NAME ${sysctl} -w net.ipv6.conf.default.disable_ipv6=1

          # Add default route through veth (metric 200) for initial VPN connection
          ${ip} -n $NETNS_NAME route add default via ${hostIP} dev ${vethNS} metric 200

          # Add kill-switch blackhole route (metric 999)
          ${ip} -n $NETNS_NAME route add blackhole 0.0.0.0/0 metric 999

          # Add LAN routes through veth
          ${lib.concatMapStringsSep "\n" (range:
            "${ip} -n $NETNS_NAME route add ${range} via ${hostIP} dev ${vethNS}"
          ) privateLANRanges}
        '';
      in "${script} %I";

      ExecStop = let
        script = pkgs.writeShellScript "netns-destroy" ''
          NETNS_NAME="$1"
          # Delete veth pair (host side)
          ${ip} link delete ${vethHost} 2>/dev/null || true
          # Delete namespace (this also cleans up the veth inside)
          ${ip} netns delete $NETNS_NAME 2>/dev/null || true
          # Clean up namespace resolv.conf
          rm -rf /etc/netns/$NETNS_NAME
        '';
      in "${script} %I";
    };
  };

  # WireGuard service running inside the VPN namespace (Proton VPN)
  systemd.services.wg-proton = {
    description = "WireGuard connection to Proton VPN (in network namespace)";
    after = [ "network-online.target" "netns@${namespaceName}.service" ];
    wants = [ "network-online.target" ];
    requires = [ "netns@${namespaceName}.service" ];
    bindsTo = [ "netns@${namespaceName}.service" ];
    wantedBy = [ "multi-user.target" ];

    # wg-quick is a bash script that calls ip, wireguard tools, etc.
    path = [ pkgs.iproute2 pkgs.wireguard-tools pkgs.bash ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      # Use the persistent network namespace created by ip netns add
      NetworkNamespacePath = "/var/run/netns/${namespaceName}";

      ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up /etc/wireguard/proton.conf";
      ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down /etc/wireguard/proton.conf";

      # WireGuard needs CAP_NET_ADMIN for interface/route setup
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
    };
  };

  # nftables firewall rules for NAT and forwarding
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet nat {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          # Masquerade WireGuard traffic (UDP 51820) so VPN servers can respond
          ip saddr ${vethSubnet} udp dport 51820 masquerade

          # Masquerade (NAT) traffic from VPN namespace going to LAN
          # This makes traffic from namespace appear to come from the host
          ip saddr ${vethSubnet} ip daddr 192.168.68.0/24 masquerade
        }
      }

      table inet filter {
        chain forward {
          type filter hook forward priority filter; policy drop;

          # Allow established/related connections (stateful firewall)
          ct state { established, related } accept

          # Allow WireGuard traffic (UDP port 51820) to reach VPN servers
          # This is needed to establish the tunnel through the host network
          iifname "${vethHost}" udp dport 51820 accept

          # Allow forwarding FROM veth ONLY to LAN destinations
          # This blocks non-VPN internet traffic when VPN is down (kill-switch)
          iifname "${vethHost}" ip daddr 192.168.68.0/24 accept

          # Allow forwarding TO veth from anywhere (return traffic)
          oifname "${vethHost}" accept
        }
      }
    '';
  };
}

# To configure a service to use this VPN namespace, use NetworkNamespacePath:
#
#   systemd.services.<service-name> = {
#     after = [ "wg-proton.service" ];
#     requires = [ "wg-proton.service" ];
#     bindsTo = [ "wg-proton.service" ];
#     serviceConfig = {
#       NetworkNamespacePath = "/var/run/netns/vpn";
#       # ... other service config ...
#     };
#   };
#
# Services in the VPN namespace will:
#   - Route all internet traffic through the WireGuard tunnel (wg0)
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
