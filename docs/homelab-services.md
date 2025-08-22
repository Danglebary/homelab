# Homelab Services Inventory

## Overview
Comprehensive inventory of all Docker services planned for the HL15 homelab server, including their data requirements, network needs, and interdependencies. This document serves as the foundation for storage organization, network topology, and service orchestration planning.

## Service Categories

### Core Media Services

#### Plex Media Server
- **Purpose**: Media streaming server with hardware transcoding
- **External Access**: Yes (built-in remote access + optional Cloudflare tunnel)
- **Remote Access**: Built-in Plex remote access (lifetime Plex Pass grandfathered)
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/plex/` (NVMe)
  - Media Library: `/mnt/vault/media/` (ZFS)
  - Transcoding Temp: `/mnt/vault/temp/transcoding/` (ZFS)
  - Local Metadata: Stored alongside media files in `/mnt/vault/media/` (ZFS)
- **Network**: Default bridge network
- **Dependencies**: ZFS vault pool, transcoded media from Tdarr pipeline
- **Hardware**: Uses Quadro P1000 for hardware transcoding
- **Access Note**: Existing users grandfathered for free remote access, no mobile unlock fees

#### Sonarr (TV Shows)
- **Purpose**: TV show management and automation (non-anime content)
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/sonarr/shows/` (NVMe)
  - Media Library: `/mnt/vault/media/shows/` (ZFS)
  - Import Monitoring: `/mnt/vault/temp/transcoded/` (ZFS)
- **Network**: Default bridge network
- **Dependencies**: Prowlarr (indexers), Deluge (downloads), Tdarr (transcoding)
- **Pipeline Role**: Receives Overseerr requests, manages downloads, imports transcoded media

#### Sonarr (Anime Shows)
- **Purpose**: Dedicated anime management and automation
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/sonarr/anime/` (NVMe)
  - Media Library: `/mnt/vault/media/anime/` (ZFS)
  - Import Monitoring: `/mnt/vault/temp/transcoded/` (ZFS)
- **Network**: Default bridge network
- **Dependencies**: Prowlarr (indexers), Deluge (downloads), Tdarr (transcoding)
- **Pipeline Role**: Dedicated anime processing for better search efficiency and organization
- **Rationale**: Separate instance prevents API waste, improves search performance, and provides better anime-specific organization

#### Radarr (Movies)
- **Purpose**: Movie management and automation
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/radarr/movies/` (NVMe)
  - Media Library: `/mnt/vault/media/movies/` (ZFS)
  - Import Monitoring: `/mnt/vault/temp/transcoded/` (ZFS)
- **Network**: Default bridge network
- **Dependencies**: Prowlarr (indexers), Deluge (downloads), Tdarr (transcoding)
- **Pipeline Role**: Receives Overseerr requests, manages downloads, imports transcoded media

#### Prowlarr (Indexer Management)
- **Purpose**: Centralized indexer management for *arr stack
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/prowlarr/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: None (provides service to Sonarr/Radarr instances)
- **Pipeline Role**: Proxies indexer requests from all *arr instances

#### Overseerr (Media Requests)
- **Purpose**: User-friendly media request interface for family/friends
- **External Access**: Yes via Cloudflare Zero Trust (request.halfblown.dev)
- **Remote URL**: `request.halfblown.dev`
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/overseerr/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: Sonarr/Radarr instances (sends requests to)
- **Pipeline Role**: Entry point for user media requests
- **Access Control**: Email-based authentication via Cloudflare, monthly re-auth required

#### Tdarr (Transcoding Automation)
- **Purpose**: Automated transcoding/re-encoding for consistent HEVC format
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/tdarr/` (NVMe)
  - Input Monitoring: `/mnt/vault/temp/downloads/completed/` (ZFS)
  - Processing Workspace: `/mnt/vault/temp/transcoding/` (ZFS)
  - Output Directory: `/mnt/vault/temp/transcoded/` (ZFS)
- **Network**: Default bridge network
- **Dependencies**: Completed downloads from Deluge
- **Pipeline Role**: Processes downloaded media, creates optimized versions for *arr import
- **Hardware**: Uses Quadro P1000 for hardware acceleration

#### Deluge (BitTorrent Client)
- **Purpose**: BitTorrent downloads with VPN isolation
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/deluge/` (NVMe)
  - Downloads: `/mnt/vault/temp/downloads/` (ZFS)
    - Active: `/mnt/vault/temp/downloads/pending/`
    - Completed: `/mnt/vault/temp/downloads/completed/`
    - Failed: `/mnt/vault/temp/downloads/failed/`
- **Network**: VPN-isolated network via Gluetun
- **Dependencies**: Gluetun (VPN gateway)
- **Pipeline Role**: Downloads media requested by Sonarr/Sonarr-Anime/Radarr

### Infrastructure Services

#### Gluetun (VPN Gateway)
- **Purpose**: VPN gateway with kill-switch for torrent traffic isolation
- **External Access**: No
- **Storage Requirements**:
  - Config: `/opt/homelab/services/gluetun/` (NVMe)
- **Network**: Creates isolated VPN network for torrent services
- **Dependencies**: None (provides networking to other services)
- **Pipeline Role**: Ensures all torrent traffic routes through VPN

#### Profilarr (Configuration Management)
- **Purpose**: Automated custom formats and quality profiles management for *arr stack
- **External Access**: Admin only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/profilarr/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: Dictionarry database, Sonarr, Sonarr-Anime, Radarr
- **Pipeline Role**: Syncs version-controlled custom formats and quality profiles to all *arr instances
- **Integration**: Uses Dictionarry database for 2160p Remux profile optimized for high-quality transcoding
- **Benefits**: Eliminates manual custom format management, ensures consistent quality across all *arr instances

#### Pi-hole (DNS & Ad Blocking)
- **Purpose**: Network-wide DNS and ad/tracker blocking
- **External Access**: Admin interface only via Cloudflare Zero Trust
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/pihole/` (NVMe)
  - Logs: `/opt/homelab/services/pihole/logs/` (NVMe, 7-day retention)
- **Network**: Host networking for DNS (port 53)
- **Dependencies**: None (provides DNS to entire network)
- **Network Role**: Primary DNS server for home network (192.168.68.100:53)

### Monitoring & Management Services


#### Alloy (Telemetry Collection)
- **Purpose**: Unified telemetry collection for logs, metrics, and traces
- **External Access**: Admin only (internal service)
- **Storage Requirements**:
  - Config: `/opt/homelab/services/alloy/` (NVMe)
  - Temporary Data: `/var/log/homelab/alloy/` (NVMe)
- **Network**: Default bridge network with access to all services
- **Dependencies**: None (provides data to Loki, Prometheus, Tempo)
- **Collection Sources**: Service logs from `/var/log/homelab/`, Prometheus metrics, OpenTelemetry traces
- **Data Flow**: Local logs → Alloy → Centralized storage on ZFS

#### Loki (Log Aggregation)
- **Purpose**: Centralized log storage and querying
- **External Access**: Admin only via Cloudflare Zero Trust (via Grafana)
- **Storage Requirements**:
  - Config: `/opt/homelab/services/loki/` (NVMe)
  - Log Data: `/mnt/vault/telemetry/loki/` (ZFS, 3-month retention)
  - Archive: `/mnt/vault/telemetry/archived/` (ZFS, compressed long-term)
- **Network**: Default bridge network
- **Dependencies**: Alloy (log collection)
- **Integration**: Grafana data source for unified log/metrics dashboards

#### Prometheus (Metrics Collection)
- **Purpose**: Time-series metrics collection and storage
- **External Access**: Admin only via Cloudflare Zero Trust (via Grafana)
- **Storage Requirements**:
  - Config: `/opt/homelab/services/prometheus/` (NVMe)
  - Metrics Data: `/mnt/vault/telemetry/metrics/` (ZFS, 3-month retention)
- **Network**: Default bridge network
- **Dependencies**: Alloy (metrics collection), service endpoints
- **Data Sources**: Container metrics, system metrics, service-specific metrics

#### Grafana (Unified Observability Dashboard)
- **Purpose**: Metrics, logs, and trace visualization with unified dashboards
- **External Access**: Admin only via Cloudflare Zero Trust (monitor.halfblown.dev)
- **Remote URL**: `monitor.halfblown.dev`
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/grafana/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: Prometheus (metrics), Loki (logs), Tempo (traces - future)
- **Dashboards**: System performance, service health, resource usage, log analysis
- **Integration**: Single pane of glass for all observability data

#### Homepage (Dashboard)
- **Purpose**: Central dashboard for service access and status overview
- **External Access**: Admin only via Cloudflare Zero Trust (admin.halfblown.dev)
- **Remote URL**: `admin.halfblown.dev`
- **Storage Requirements**:
  - Config: `/opt/homelab/services/homepage/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: All services (provides links and status for)
- **Features**: Service shortcuts, status widgets, system info
- **Access Control**: Admin-only access, not intended for family/friends

### Self-Hosting Services

#### Immich (Photo Management)
- **Purpose**: Photo management and sharing (limited family access)
- **External Access**: Limited family access via Cloudflare Zero Trust (immich.halfblown.dev)
- **Remote URL**: `immich.halfblown.dev`
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/immich/` (NVMe)
  - Photo Library: `/mnt/vault/immich/` (ZFS)
  - Thumbnails/Cache: `/opt/homelab/services/immich/cache/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: None
- **Access Control**: Limited family members via Cloudflare Zero Trust email authentication

#### Nextcloud (File Sync)
- **Purpose**: File synchronization and collaboration
- **External Access**: Admin only via Cloudflare Zero Trust (nextcloud.halfblown.dev)
- **Remote URL**: `nextcloud.halfblown.dev`
- **Storage Requirements**:
  - Config/Database: `/opt/homelab/services/nextcloud/` (NVMe)
  - File Storage: `/mnt/vault/nextcloud/` (ZFS)
- **Network**: Default bridge network
- **Dependencies**: None
- **Features**: File sync, calendar, contacts, notes

### Future Services (Planned)

#### Custom Subtitle Service
- **Purpose**: Automated subtitle generation using Whisper.cpp
- **External Access**: No (internal pipeline service)
- **Storage Requirements**:
  - Config: `/opt/homelab/services/subtitle-service/` (NVMe)
  - Processing Workspace: `/mnt/vault/temp/subtitles/` (ZFS)
  - Model Files: `/opt/homelab/services/subtitle-service/models/` (NVMe)
- **Network**: Default bridge network
- **Dependencies**: Transcoded media from Tdarr
- **Pipeline Role**: Generates subtitles after transcoding, before final media placement
- **Integration**: Slots between Tdarr and *arr import steps

## Media Processing Pipeline

### Complete Workflow
1. **User Request**: Overseerr → Sonarr/Sonarr-Anime/Radarr
2. **Content Discovery**: Sonarr/Sonarr-Anime/Radarr → Prowlarr → Indexers
3. **Download**: Sonarr/Sonarr-Anime/Radarr → Deluge (via VPN)
4. **File Movement**: Deluge → `/mnt/vault/temp/downloads/completed/`
5. **Transcoding**: Tdarr monitors completed downloads → transcodes → `/mnt/vault/temp/transcoded/`
6. **Import**: Sonarr/Sonarr-Anime/Radarr monitors transcoded directory → moves to final media location
7. **Metadata**: Plex scans media directory → generates metadata/thumbnails alongside media
8. **Quality Management**: Profilarr syncs custom formats from Dictionarry to all *arr instances
9. **Future**: Subtitle service integration between steps 5-6

### Storage Flow
```
Downloads: /mnt/vault/temp/downloads/pending/ → completed/
Transcoding: /mnt/vault/temp/transcoding/ (workspace)
Staging: /mnt/vault/temp/transcoded/ (ready for import)
Final: /mnt/vault/media/{movies|shows|anime}/ (with metadata/thumbnails)
```

## Network Topology Requirements

### Network Segmentation
- **Default Bridge Network**: Most services
- **VPN Network**: Deluge, Gluetun
- **Host Network**: Pi-hole (DNS requirements)
- **External Access**: Cloudflare Zero Trust tunnels → services with external access needs

### DNS Configuration
- **Primary DNS**: Pi-hole on homelab server (192.168.68.100)
- **Secondary DNS**: Cloudflare (1.1.1.1, 1.0.0.1)
- **Network Integration**: TP-Link Deco mesh configured to use Pi-hole

### External Access Strategy
- **Domain**: halfblown.dev (Cloudflare managed)
- **Method**: Cloudflare Zero Trust tunnels
- **SSL**: Handled automatically by Cloudflare
- **Access Control**: Email-based authentication with monthly re-auth
- **Service URLs**:
  - `admin.halfblown.dev` → Homepage (admin dashboard)
  - `monitor.halfblown.dev` → Grafana (admin monitoring and observability)
  - `request.halfblown.dev` → Overseerr (family/friends media requests)
  - `immich.halfblown.dev` → Immich (limited family/friends photo access)
  - `nextcloud.halfblown.dev` → Nextcloud (admin file sync)
  - Additional admin services accessible via Cloudflare Zero Trust
- **Benefits**: No port forwarding, built-in DDoS protection, simplified SSL management

## Resource Considerations

### Storage Distribution
- **NVMe (Fast, Limited)**: Configs, databases, caches, active processing, local logging
- **ZFS (Large, Reliable)**: Media libraries, downloads, user data, centralized telemetry data

### Hardware Utilization
- **CPU**: Transcoding (Tdarr), media processing, log aggregation
- **GPU**: Hardware acceleration (Plex, Tdarr via Quadro P1000)
- **RAM**: Database operations, media processing, system caches, observability stack
- **Network**: Upload bandwidth management for concurrent streams, telemetry collection

### Centralized Logging Strategy
- **Local Logging**: Services log to `/var/log/homelab/[service]/` for fast writes
- **Collection**: Alloy collects logs from local directories 
- **Aggregation**: Logs shipped to `/mnt/vault/telemetry/loki/` for central storage
- **Retention**: 3-month active retention, compressed archival for historical analysis
- **Benefits**: Fast local logging + reliable centralized storage + historical trends

### Data Retention Policies
- **Local Service Logs**: 7 days (rotated by Alloy)
- **Centralized Logs**: 3 months active, 1+ year archived
- **Metrics Data**: 3 months (Prometheus on ZFS)
- **Pi-hole Logs**: 7 days local
- **Media Files**: Permanent (with ZFS snapshots)
- **Download Temp Files**: Cleaned after successful processing

## Service Dependencies Summary

### Critical Path Dependencies
1. **ZFS Vault Pool** → Media services (Plex, Sonarr, Sonarr-Anime, Radarr, Tdarr)
2. **Gluetun VPN** → Deluge
3. **Prowlarr** → Sonarr/Sonarr-Anime/Radarr indexer access
4. **Cloudflare Zero Trust** → External service access
5. **Dictionarry/Profilarr** → Custom formats for all *arr instances
6. **Pipeline Order**: Deluge → Tdarr → Sonarr/Sonarr-Anime/Radarr → Plex

### Monitoring Dependencies
- **Prometheus** collects metrics from all services
- **Grafana** visualizes Prometheus and Loki data with unified dashboards
- **Loki** aggregates logs from all services via Alloy
- **Homepage** provides status overview of all services

## Configuration Management

### Git Repository Structure
```
/opt/homelab/services/
├── service-name/
│   ├── compose.yml          # Docker Compose configuration
│   ├── .env                 # Service secrets (gitignored)
│   ├── .env.example         # Template (in git)
│   └── config/              # Service-specific config files
```

### Deployment Strategy
- **Infrastructure as Code**: All configurations in git
- **Secret Management**: Individual .env files per service
- **Updates**: Git-based deployment with validation
- **Rollback**: Git checkout + service restart

## Success Criteria

- [x] All services defined with clear storage requirements
- [x] Media processing pipeline workflow documented
- [x] Network topology requirements identified
- [x] Service dependencies mapped
- [x] External access strategy defined (Cloudflare Zero Trust)
- [x] Resource allocation considerations documented
- [x] Future service integration points planned
- [x] Anime-specific Sonarr instance added for improved organization
- [x] Profilarr/Dictionarry integration for automated quality management
- [x] Subdomain structure defined for halfblown.dev services