# Homelab - HL15 Media Server & Self-Hosting Setup

A NixOS-based homelab built on an HL15 2.0 server for media streaming and self-hosting services.

## Hardware

- **Server**: HL15 2.0 from 45HomeLab
- **Storage**: ZFS pool with mirrored vdevs for media, NVMe for OS/configs/cache
- **Network**: Dual NICs bonded via LACP
- **GPU**: Hardware transcoding support for Plex

## Architecture Overview

```
                                    Internet
                                        │
                              ┌─────────┴─────────┐
                              │  Cloudflare Zero  │
                              │      Trust        │
                              └─────────┬─────────┘
                                        │
┌───────────────────────────────────────┴───────────────────────────────────┐
│                                 Host                                      │
│                                                                           │
│  ┌─────────────────────────────┐    ┌──────────────────────────────────┐  │
│  │      Host Services          │    │        VPN Namespace             │  │
│  │                             │    │                                  │  │
│  │  • Plex (media streaming)   │    │  ┌────────────────────────────┐  │  │
│  │  • Overseerr (requests)     │    │  │     OpenVPN (PIA)          │  │  │
│  │  • Homepage (dashboard)     │    │  │     tun0 interface         │  │  │
│  │  • Cloudflared (tunnel)     │    │  └────────────┬───────────────┘  │  │
│  │                             │    │               │                  │  │
│  │                             │◄───┼───veth pair───┤                  │  │
│  │                             │    │               │                  │  │
│  │                             │    │  • Deluge (linux ISOs)           │  │
│  │                             │    │  • Radarr                        │  │
│  │                             │    │  • Sonarr                        │  │
│  │                             │    │  • Prowlarr                      │  │
│  │                             │    │  • FlareSolverr                  │  │
│  └─────────────────────────────┘    └──────────────────────────────────┘  │
│                                                                           │
│  bond0 (eno1 + eno2, LACP 802.3ad)                                        │
└───────────────────────────────────────────────────────────────────────────┘
                                        │
                              ┌─────────┴─────────┐
                              │   Home Network    │
                              └───────────────────┘
```

## NixOS Configuration Structure

```
nixos/
├── flake.nix                 # Flake definition with inputs
├── configuration.nix         # Root config, imports modules
├── hardware-configuration.nix
└── modules/
    ├── system/
    │   ├── file-system/      # ZFS pool, snapshots, tmpfiles
    │   ├── network/          # Networking, VPN namespace, firewall, CF tunnel
    │   ├── users.nix         # User accounts
    │   └── groups.nix        # Shared permission groups
    └── services/             # One file per service
        ├── plex.nix
        ├── deluge.nix
        ├── radarr.nix
        └── ...
```

Each service is a standalone module that can be enabled/disabled. Services define their own systemd units, users, and directory requirements.

## Key Design Decisions

### VPN Namespace Isolation

Download services (Deluge, Radarr, Sonarr, Prowlarr) run in an isolated network namespace where all traffic is forced through a VPN tunnel. A kill-switch (blackhole route) prevents any traffic from leaking if the VPN drops.
IPV6 is disabled in the namespace to also prevent leaks.

The namespace connects to the host via a veth pair, allowing web UIs of services within the namespace to be accessed from
the host/LAN.

### Systemd Service Hardening

All services run with hardened systemd settings:
- `ProtectSystem=strict` - Read-only filesystem except allowed paths
- `PrivateTmp=true` - Isolated /tmp
- `NoNewPrivileges=true` - Can't gain additional privileges
- `RestrictAddressFamilies` - Limited to required socket types
- Network namespace binding for VPN services

### Storage Layout

```
/mnt/vault/                   # ZFS pool
├── media/
│   ├── movies/
│   ├── shows/
│   └── anime/
└── downloads/
    ├── incomplete/
    └── complete/

/var/lib/services/            # Service state/configs
├── plex/
├── radarr/
└── ...
```

ZFS provides automatic snapshots, scrubbing, and compression. Media and downloads are on the pool; service configs are on faster NVMe storage.

### Remote Access

Cloudflare Zero Trust tunnel provides secure external access without exposing ports to the internet. Only Overseerr is exposed externally for media requests currently.

## Running Commands

The `justfile` provides common operations:

```bash
just sys-up-test  # NixOS system rebuild dry-run
just sys-up       # Rebuild and switch to new NixOS config
just sys-down     # Rollback to previous NixOS config
just hp-up        # Update HomePage config
just pull         # Fetch & Pull latest changes from git (git fetch && git pull)
```

## Documentation

- [Cloudflare Tunnel Setup](docs/cloudflare_tunnel_setup_guide.md)
- [ZFS Pool Expansion](docs/zfs_pool_expansion_guide.md)
