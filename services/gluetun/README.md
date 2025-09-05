# Gluetun VPN Gateway

## Service Overview
- **Purpose**: VPN gateway with kill-switch protection for isolated torrent traffic
- **Category**: infrastructure
- **External Access**: No - internal service only
- **Instance**: N/A - single instance

## Service Configuration
- **Service User**: `gluetun` (PUID: 2006)
- **Domain Groups**: `services` (GID: 3000)
- **Dependencies**: None (foundational infrastructure service)
- **Pipeline Stage**: N/A - infrastructure service

## Container Settings
**Ports**: 8388 (HTTP proxy), 8888 (Shadowsocks), plus forwarded ports for dependent services
**Resources**: 0.5-1.0 CPU, 256-512MB RAM
**Network**: bridge (creates VPN-isolated network for other containers)
**Special Requirements**: Privileged mode for network management, NET_ADMIN capability

## Environment Variables
```bash
# Service Identity (universal)
PUID=2006
PGID=3000
TZ=America/Los_Angeles

# VPN Provider Configuration
VPN_SERVICE_PROVIDER=private internet access
OPENVPN_USER=
OPENVPN_PASSWORD=
SERVER_REGIONS=US East

# Kill Switch & DNS
FIREWALL_VPN_INPUT_PORTS=
DNS_KEEP_NAMESERVER=off
DNS_ADDRESS=1.1.1.1

# HTTP Proxy Configuration
HTTPPROXY=on
HTTPPROXY_LOG=on
HTTPPROXY_USER=
HTTPPROXY_PASSWORD=

# Health Check & Logging
HEALTH_VPN_DURATION_INITIAL=6s
LOG_LEVEL=info
```

## Storage Access
**Read/Write Access**: `/var/lib/services/gluetun/` (VPN configuration and state files)
**Read-Only Access**: None

## Health Check
**Startup**: Container logs show "VPN is up" and external IP shows VPN provider's IP
**Runtime**: `curl --proxy http://gluetun:8888 https://ipinfo.io` should show VPN IP, not home IP  
**Common Issues**: 
- VPN credentials incorrect - check OPENVPN_USER and OPENVPN_PASSWORD
- Kill-switch blocking traffic - verify FIREWALL_VPN_INPUT_PORTS includes required ports for dependent services
- DNS resolution failing - ensure DNS_ADDRESS is accessible through VPN
- Container startup fails - check /dev/net/tun device is available and NET_ADMIN capability granted

## Notes
- All containers using `network_mode: "container:gluetun"` will route through VPN
- If Gluetun stops, dependent containers lose network access (kill-switch protection)
- HTTP proxy on port 8888 allows testing VPN connection from other containers
- PIA port forwarding has limitations - works mainly for P2P applications
- Uses OpenVPN (WireGuard requires custom configuration with PIA)
- Health check verifies internet connectivity through VPN tunnel