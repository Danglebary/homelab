# Media Pipeline Processing & Access Control

## Overview
Detailed documentation of the media processing pipeline, file permissions, and cleanup strategies for the homelab media services. This document ensures proper access control throughout the entire media workflow from download to final consumption.

## Pipeline Architecture

### Processing Flow
```
1. Request  : Overseerr → Sonarr/Radarr (adds to DB, begins searching)
2. Search   : Sonarr/Radarr → Prowlarr → Indexers → Prowlarr → Sonarr/Radarr
3. Download : Sonarr/Radarr → Deluge → /mnt/vault/temp/downloads/pending/
4. Complete : Deluge → /mnt/vault/temp/downloads/completed/ + begins seeding
5. Process  : Tdarr → reads downloads/completed → creates new files in /mnt/vault/transcoded/
6. Import   : Sonarr/Radarr → reads transcoded → hardlinks to /mnt/vault/media/{anime|shows|movies}/
7. Scan     : Plex → adds metadata and thumbnails alongside media files
8. Complete : Media ready for viewing via Plex server
9. Cleanup  : Just commands → removes old files from downloads/completed and transcoded after verification
```

### Directory Structure
```
/mnt/vault/
├── temp/downloads/
│   ├── pending/              # Active downloads (deluge writes)
│   └── completed/            # Seeding + tdarr source (deluge seeds, tdarr reads, cleanup deletes)
├── transcoded/               # Transcoded files (tdarr writes, sonarr/radarr read, cleanup deletes)
└── media/
    ├── anime/                # Both anime shows and movies (sonarr.anime, radarr.anime hardlink)
    ├── shows/                # Non-anime TV shows (sonarr.shows hardlinks)
    └── movies/               # Non-anime movies (radarr.movies hardlinks)
```

## Group-Based Access Control

### Content Type Groups
| Group    | GID  | Purpose                     | Directories                |
| -------- | ---- | --------------------------- | -------------------------- |
| `anime`  | 3010 | Anime content management    | `/mnt/vault/media/anime/`  |
| `shows`  | 3011 | TV shows content management | `/mnt/vault/media/shows/`  |
| `movies` | 3012 | Movies content management   | `/mnt/vault/media/movies/` |

### Processing Stage Groups  
| Group         | GID  | Purpose                      | Directories                     |
| ------------- | ---- | ---------------------------- | ------------------------------- |
| `services`    | 3000 | Base group for all services  | `/var/lib/services/*`           |
| `downloads`   | 3020 | Download management          | `/mnt/vault/temp/downloads/*`   |
| `transcoding` | 3021 | Transcoding pipeline         | `/mnt/vault/transcoded/`        |
| `cleanup`     | 3025 | Cleanup old processing files | All temp/processing directories |

## Service Group Memberships

### Download & Processing Services
```nix
deluge: [downloads]                          # Downloads to pending, moves to completed, seeds
tdarr: [transcoding]                        # Reads downloads/completed, writes to transcoded
```

### Content Management Services
```nix
sonarr.shows: [shows]                       # Reads transcoded, hardlinks to shows library
sonarr.anime: [anime]                       # Reads transcoded, hardlinks to anime library
radarr.movies: [movies]                     # Reads transcoded, hardlinks to movies library  
radarr.anime: [anime]                       # Reads transcoded, hardlinks to anime library
```

### User Interface & Support Services
```nix
prowlarr: [services]                        # Indexer management (API-based, no media access)
overseerr: [services]                       # Media requests (API-based, no media access)
profilarr: [services]                       # Quality management (API-based, no media access)
```

### Media Server
```nix
plex: [anime, shows, movies]                # Direct access to all media directories for metadata management
```

### Infrastructure & Observability Services
```nix
gluetun: [services]                         # VPN gateway
pihole: [services]                          # DNS and ad blocking
homepage: [services]                        # Dashboard service
alloy: [services]                           # Telemetry collection
loki: [services]                            # Log aggregation
prometheus: [services]                      # Metrics collection
grafana: [services]                         # Observability dashboards
immich: [services]                          # Photo management
nextcloud: [services]                       # File sync
```

### Human Users
```nix
admin: [cleanup, anime, shows, movies, downloads, transcoding]
```

## Directory Permissions

### Media Storage (Final Destinations)
```nix
"d /mnt/vault/media/anime 2775 root anime -"    # Anime group can read/write, setgid inheritance
"d /mnt/vault/media/shows 2775 root shows -"    # Shows group can read/write, setgid inheritance
"d /mnt/vault/media/movies 2775 root movies -"  # Movies group can read/write, setgid inheritance
```

### Processing Pipeline (Temporary Storage)
```nix
"d /mnt/vault/temp/downloads 2775 root downloads -"
"d /mnt/vault/temp/downloads/pending 2775 root downloads -"
"d /mnt/vault/temp/downloads/completed 2775 root downloads -"
"d /mnt/vault/transcoded 2775 root transcoding -"
```

**Note:** The `2775` permission includes the setgid bit (2) which ensures that files created in these directories automatically inherit the group ownership. This prevents permission issues when multiple services need to process the same files through the pipeline.

## Cleanup Strategy

### Safety Window Approach
- **Transcoding**: Copy-based processing preserves originals during transcoding
- **Verification Period**: Files remain in processing directories for quality verification
- **Controlled Cleanup**: Manual cleanup via Just commands or future automation

### Just Commands for Cleanup
```bash
# Clean up downloads older than 14 days (after quality verification)
just cleanup-downloads 14

# Clean up transcoding workspace older than 7 days
just cleanup-transcoding 7

# Emergency space recovery (clean everything older than X days)
just cleanup-pipeline 30
```

### Cleanup Permissions
- **cleanup group**: Can delete files from all temp processing directories
- **admin user**: Member of cleanup group for manual maintenance
- **Future automation**: Can add cron jobs or services to cleanup group

## Benefits of This Architecture

### Access Control
- ✅ **Least Privilege**: Services only access directories they need
- ✅ **Content Separation**: Different content types isolated by group
- ✅ **Stage Separation**: Processing stages have separate permissions
- ✅ **Safe Processing**: Copy-based transcoding preserves originals

### Pipeline Safety
- ✅ **No chmod 777**: Proper permissions prevent permission issues
- ✅ **Failure Recovery**: Original files preserved until cleanup
- ✅ **Quality Control**: Verification period before cleanup
- ✅ **Space Efficiency**: Controlled cleanup prevents disk bloat

### Operational Benefits
- ✅ **Clear Ownership**: Each directory has a clear owning group
- ✅ **Troubleshooting**: Admin has access to all areas for debugging
- ✅ **Flexibility**: Future services can join appropriate groups
- ✅ **Scalability**: Group-based model scales with additional services

## Future Considerations

### Automation Opportunities
- Cron-based cleanup jobs (members of cleanup group)
- Quality verification services (read access to transcoded content)
- Monitoring services (read access for disk usage tracking)

### Additional Content Types
- Music content could follow similar patterns
- Audiobooks, podcasts, etc. can use same group model

### Enhanced Security
- Service-specific directories under `/var/lib/services/[service]/`
- Log rotation and cleanup for service-specific logs
- Backup strategies that respect group permissions