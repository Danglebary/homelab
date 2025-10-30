# Gluetun VPN Gateway

## Service Overview
- **Purpose**: VPN client container that routes other containers' traffic through VPN tunnel
- **Category**: infrastructure
- **External Access**: No (internal infrastructure only)
- **Instance**: N/A - single instance

## Service Configuration
- **User/Group**: `root` (requires NET_ADMIN capability for network interface management)
- **Dependencies**: None (foundation for VPN-dependent services)
- **Pipeline Stage**: N/A - infrastructure service

## Container Settings
**Ports**: 8112 (Deluge WebUI), 58846 (Deluge daemon), 9696 (Prowlarr)
**Resources**: Minimal - <1 CPU core, ~64MB RAM
**Network**: bridge (creates isolated network for VPN-routed services)
**Special Requirements**:
- `CAP_NET_ADMIN` capability for VPN tunnel management
- `/dev/net/tun` device access (TUN/TAP kernel module)
- Runs as root (`user: "0:0"`) for VPN operations

## Environment Variables
```bash
# Timezone
TZ=America/Los_Angeles

# VPN Provider (Private Internet Access)
PIA_USERNAME=your_pia_username
PIA_PASSWORD=your_pia_password
VPN_REGION=US West

# Firewall Configuration
FIREWALL_OUTBOUND_SUBNETS=192.168.68.0/24
```

## Storage Access
**Read/Write Access**: `./data/` (VPN state and server list cache, relative to compose file)
**Read-Only Access**: None

## Health Check
Gluetun includes a built-in health check system that monitors VPN connectivity.

**How it works**:
- Internal health server listens on port 9999 (container-internal only)
- Docker healthcheck uses `/gluetun-entrypoint healthcheck` command
- Checks connectivity to `cloudflare.com:443` by default
- Container marked as "healthy" once VPN is connected and stable

**Startup verification**:
- Container logs show "Initialization Sequence Completed"
- Docker status shows "healthy" after ~30 seconds: `docker ps`
- Check public IP via: `docker exec gluetun wget -qO- ifconfig.me`

**Runtime monitoring**:
- VPN connection remains stable (no reconnection loops in logs)
- Services using this network can access the internet
- Kill-switch is active (traffic blocked if VPN disconnects)

**Common Issues**:
- **Authentication failures**: Verify PIA_USERNAME and PIA_PASSWORD in .env
- **Connection timeouts**: Try different VPN_REGION (some regions may be congested)
- **Local network not accessible**: Check FIREWALL_OUTBOUND_SUBNETS matches your network (run `ip addr` to verify)
- **Services can't connect**: Ensure other containers use `network_mode: "container:gluetun"`

## Using Gluetun with Other Services

To route a service through the Gluetun VPN tunnel:

1. **Remove the service's `ports` section** (ports are exposed via Gluetun instead)
2. **Add ports to Gluetun's compose.yml** (see ports section above)
3. **Set network mode** in the service's compose.yml:
   ```yaml
   services:
     deluge:
       network_mode: "container:gluetun"
       depends_on:
         - gluetun
   ```

## Verifying VPN Connection

Check that traffic is routed through VPN:
```bash
# Check Gluetun's public IP (should be VPN server IP)
docker exec gluetun wget -qO- ifconfig.me

# Check a service using Gluetun (should match Gluetun's IP)
docker exec deluge wget -qO- ifconfig.me

# Your actual server IP (should be different from above)
wget -qO- ifconfig.me
```

All three IPs should be different:
- Gluetun: VPN provider's IP
- Service (Deluge): Same as Gluetun (using VPN)
- Host server: Your actual ISP IP

## Notes
- **Kill-switch enabled**: If VPN disconnects, all traffic through Gluetun is blocked (prevents IP leaks)
- **Port forwarding**: PIA supports port forwarding for improved torrent performance (configure if needed)
- **Region selection**: Choose geographically close regions for better performance
- **Health monitoring**: Use health check endpoint for automated monitoring/alerting
- **Multiple services**: Multiple containers can share the same Gluetun instance via `network_mode`
