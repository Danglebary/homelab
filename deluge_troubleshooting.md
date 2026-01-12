# Deluge Troubleshooting Log

## Issue Summary
After upgrading to NixOS 25.11, Deluge daemon starts but torrents remain paused and cannot be resumed. Web UI shows "IP: n/a".

## Root Cause
Libtorrent (the backend library) cannot bind to UDP ports, preventing torrent communication. This appears to be a capabilities + sandboxing issue when running in a network namespace.

## Key Symptoms
- Deluge Web UI accessible and shows torrents
- Torrents show as "Paused" and cannot be resumed
- "IP: n/a" in Web UI
- No UDP ports listening: `sudo ip netns exec vpn ss -ulnp | grep deluge` returns nothing
- TCP port 58846 (RPC) works fine
- Other services in same VPN namespace (Prowlarr, Radarr) work perfectly

## Diagnostic Findings

### From Debug Logs
```
session_error: (97 Address family not supported by protocol)
listen_failed: listening on 0.0.0.0:0 failed: [enum_if] [TCP] Address family not supported by protocol
listen_failed: listening on 0.0.0.0:0 failed: [enum_route] [TCP] Address family not supported by protocol
Listening to UI on: None:58846 and bittorrent on: None
```

Key observation: libtorrent tries to enumerate network interfaces (`[enum_if]`) and routes (`[enum_route]`) but fails, preventing it from binding to any port.

### VPN Configuration Context
- Services run in isolated network namespace: `/var/run/netns/vpn`
- IPv6 is disabled in the VPN namespace (via sysctl)
- OpenVPN has similar permission denied errors but works overall
- OpenVPN has `AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ]`

## Attempts & Results

### 1. ✗ Removed AF_INET6 from RestrictAddressFamilies
**Tried:** Changed from `[ "AF_INET" "AF_INET6" "AF_UNIX" ]` to `[ "AF_INET" "AF_UNIX" ]`
**Result:** No change, same errors persist
**Reasoning:** Thought systemd was allowing IPv6 attempts that failed in namespace

### 2. ✗ Added enable_ipv6=false to core.conf
**Tried:** Manually added `"enable_ipv6": false` to `/var/lib/services/deluge/core.conf`
**Result:** No change
**Reasoning:** Tried to tell Deluge/libtorrent to not use IPv6

### 3. ✗ Temporarily enabled IPv6 in VPN namespace
**Tried:**
```bash
sudo ip netns exec vpn sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo systemctl restart deluge
```
**Result:** No change
**Reasoning:** Test if IPv6 being disabled was the blocker

### 4. ✗ Added CAP_NET_ADMIN capability
**Tried:** Added `AmbientCapabilities = [ "CAP_NET_ADMIN" ]` to service
**Result:** No change
**Reasoning:** Libtorrent needs to enumerate interfaces like OpenVPN does

### 5. ✗ Added CapabilityBoundingSet
**Tried:** Added `CapabilityBoundingSet = [ "CAP_NET_ADMIN" ]` alongside AmbientCapabilities
**Result:** No change
**Reasoning:** Systemd requires both for capabilities to work with sandboxing

### 6. ⏳ Set NoNewPrivileges=false (CURRENT TEST)
**Tried:** Changed `NoNewPrivileges = true` to `false`
**Result:** PENDING TEST
**Reasoning:** ChatGPT analysis suggests NoNewPrivileges=true prevents CAP_NET_ADMIN from working in network namespaces, even with AmbientCapabilities set

## Current Configuration (deluge.nix)
```nix
AmbientCapabilities = [ "CAP_NET_ADMIN" ];
CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
NoNewPrivileges = false;  # Changed from true
RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
NetworkNamespacePath = "/var/run/netns/vpn";
```

## Next Steps if Current Fix Doesn't Work

1. **Check OpenVPN comparison:** OpenVPN works with `CAP_NET_RAW` - try adding that too
2. **Try different Deluge version:** Check if older Deluge/libtorrent from 25.05 works
3. **Alternative torrent clients:** qBittorrent or Transmission might handle namespaces better
4. **Relaxed sandboxing test:** Temporarily disable all hardening to isolate the issue:
   - Remove all Protect* directives
   - Remove RestrictAddressFamilies
   - See if it works, then add back restrictions one by one

## Working Services for Comparison
Both Prowlarr and Radarr work fine in the same VPN namespace with:
- No special capabilities
- Similar sandboxing (ProtectSystem="strict", etc.)
- But they don't need UDP ports for their operation

## Useful Diagnostic Commands
```bash
# Check if UDP ports are listening
sudo ip netns exec vpn ss -ulnp | grep deluge

# Check deluge logs with errors
journalctl -u deluge.service -n 100 | grep -i "error\|warn\|listen"

# Check what capabilities the process actually has
sudo grep Cap /proc/$(pgrep deluged)/status

# Test VPN namespace connectivity
sudo ip netns exec vpn curl ifconfig.me

# Check routes in namespace
sudo ip netns exec vpn ip route show
```

## Files Involved
- `/Users/halfblown/Documents/homelab/nixos/modules/services/deluge.nix` - Service definition
- `/var/lib/services/deluge/core.conf` - Deluge config (managed by Deluge, not NixOS)
- `/Users/halfblown/Documents/homelab/nixos/modules/system/network/vpn.nix` - VPN namespace setup
