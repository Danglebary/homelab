# Immich Photo Management

## Service Overview
- **Purpose**: Self-hosted photo and video management with machine learning features
- **Category**: self-hosting
- **External Access**: Yes - `immich.halfblown.dev` (limited family access)
- **Instance**: N/A - single instance

## Service Configuration
- **User/Group**: `root` (containers run as root for compatibility with Immich's internal user management)
- **Dependencies**: None (self-contained with PostgreSQL and Redis)
- **Pipeline Stage**: N/A - standalone service

## Container Settings
**Ports**: 2283 (external access via Cloudflare tunnels)
**Resources**: 2-4 CPU cores, 4-6GB RAM (machine learning processing)
**Network**: bridge
**Special Requirements**: Machine learning container for photo analysis, PostgreSQL with vector extensions

## Environment Variables
```bash
# Timezone
TZ=America/Los_Angeles

# Immich Application
IMMICH_VERSION=release

# Database Configuration
DB_PASSWORD=secure_database_password_here
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

## Storage Access
**Read/Write Access**: `/mnt/vault/immich/` (photo and video storage), `/var/lib/services/immich/` (database and config)
**Read-Only Access**: None

## Health Check
**Startup**: Container logs show "Immich Server is listening on port 2283", web interface accessible at http://server-ip:2283
**Runtime**: Web interface responsive, photo uploads working, machine learning processing functional
**Common Issues**:
- Database connection failures - check PostgreSQL container health and DB_PASSWORD
- Upload failures - verify /mnt/vault/immich/ permissions and disk space
- Machine learning not working - ensure sufficient RAM allocated (4GB+ recommended)

## Notes
- First user to register becomes admin - set up immediately after deployment
- Includes automatic photo analysis via machine learning container
- PostgreSQL database with vector extensions for similarity search
- Redis used for caching and background jobs
- Requires minimum 4GB RAM (6GB recommended) for optimal performance
- Storage grows with photo library size - monitor /mnt/vault/immich/ usage