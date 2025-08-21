# Homelab Project - HL15 Media Server & Self-Hosting Setup

## Project Overview
Building a comprehensive homelab on an HL15 2.0 server from 45HomeLab for media streaming, self-hosting, and learning modern infrastructure technologies. The goal is a production-quality setup that friends and family can access remotely for media requests and file sharing.

## Hardware Specifications

### Server: HL15 2.0 (45HomeLab/45Drives)
- **Motherboard:** ASRock ROMED8-2T
- **CPU:** AMD EPYC 7282 (16-core/32-thread)
- **RAM:** 256GB DDR4 ECC @ 2400MHz
- **GPU:** PNY Quadro P1000 4GB (for transcoding)
- **Network:** Dual 2.5GbE ports (bonded with LACP for ~5Gbps aggregate)

### Storage Configuration
- **Boot Drive:** 1x Kingston NV2 1TB M.2 (OS, configs, app data)
- **Cache/Fast Storage:** 2x Team Group MP33 256GB M.2 (via PCIe carrier)
- **Bulk Storage:** 2x WD Ultrastar HC560 20TB SAS (ZFS pool for media)
- **Expansion:** 13 additional hot-swap bays available for future growth

## Operating System & Philosophy

### NixOS with Flakes
- **Choice Reasoning:** Declarative configuration, reproducible builds, excellent rollback capabilities
- **Flakes Adoption:** Using flakes for better dependency management and future-proofing
- **Configuration Management:** All system config version-controlled and modularized

### ZFS Storage Strategy
- **Pool Design:** Striped-mirror (RAID10-like) with 2x 20TB drives initially
- **Expansion Plan:** Add drive pairs to expand pool capacity
- **Benefits:** Data integrity, snapshots, compression, excellent for media workloads

## Application Stack

### Core Media Services
- **Plex:** Media streaming server with hardware transcoding
- **Deluge:** BitTorrent client (VPN-routed traffic only)
- **Sonarr:** TV show management and automation
- **Radarr:** Movie management and automation  
- **Overseerr:** User-friendly media request interface for family/friends
- **Prowlarr:** Indexer management for *arr stack

### Self-Hosting Services
- **Immich:** Photo management and sharing (limited family access)
- **Nextcloud:** File sync and collaboration
- **Uptime Kuma:** Service monitoring and status page

### Infrastructure Services
- **Reverse Proxy:** TBD (Traefik/Nginx Proxy Manager)
- **VPN Gateway:** Gluetun container for torrent traffic isolation

## Network Architecture

### Physical Network
- **Switch:** UniFi US-24-250W with LACP port aggregation
- **Bonding:** 802.3ad LACP with layer3+4 hashing for optimal distribution
- **IP:** Static 192.168.68.100/24 on bond0 interface

### Application Network Segmentation
- **VPN Network:** Deluge and related torrent traffic through PIA VPN
- **Default Network:** All other services with direct internet access
- **Isolation Method:** Gluetun container as VPN gateway with kill-switch

### Remote Access
- **Primary:** Cloudflare Zero Trust tunnels (free tier, up to 50 users)
- **Domain:** halfblown.dev (managed via Cloudflare, paid through 2027)
- **Access Control:** Family/friends for Overseerr (~10 max), limited access for Immich

## Container Management

### Docker Compose Strategy
- **Orchestration:** Docker Compose for declarative service management
- **Version Control:** All compose files and configs stored in Git
- **Data Persistence:** 
  - Media storage: ZFS pool (/mnt/tank or similar)
  - App configs/databases: Boot drive (/opt/docker or similar)
  - Container images: Boot drive

### Service Dependencies
- **Storage:** ZFS pool must be mounted before media services start
- **Network:** VPN container must be healthy before torrent services start
- **Monitoring:** Uptime Kuma monitors all critical services

## Future Expansion Plans

### Storage Growth
- Add drive pairs to ZFS pool as storage needs grow
- Consider adding SSD cache/log devices
- Evaluate backup solutions when second machine available

### Service Additions
- **Possible additions:** Jellyfin (Plex alternative), Home Assistant, Grafana/Prometheus
- **Networking:** Additional VLANs or network segmentation as complexity grows

## Development Workflow & Rules

### Planning Requirements
1. **ALWAYS create a planning document before making infrastructure or configuration changes**
2. **Document reasoning for architectural decisions**
3. **Test changes with dry-run/staging when possible**
4. **Maintain rollback capability for all changes**

### Git Commit Requirements
1. **Never mention Claude Code in commit messages** - commits should appear as normal development work
2. **Always use single-line commit messages** - multi-line commits do not work properly

### Configuration Management
- **NixOS:** All system configuration in version control with proper modularity
- **Docker:** All compose files and application configs in version control
- **Documentation:** Keep CLAUDE.md and planning docs updated with changes

### Security Considerations
- **VPN Isolation:** Ensure torrent traffic never leaks outside VPN tunnel
- **Access Control:** Limit remote access to necessary services only
- **Updates:** Regular security updates for both NixOS and container images

## Current Status
- ✅ NixOS installed and configured
- ✅ Network bonding (LACP) operational with ~5Gbps aggregate bandwidth  
- ✅ Basic system configuration modularized
- ⏳ Planning Docker compose setup and ZFS configuration
- ⏳ Planning application deployment and remote access setup

## Context Notes
- **User Background:** Senior backend engineer with Kubernetes/Docker experience
- **Learning Goals:** ZFS administration, NixOS advanced features, homelab best practices
- **Priority:** Stable, maintainable setup over cutting-edge experimentation