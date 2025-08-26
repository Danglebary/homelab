# CI/CD Workflow for Homelab Infrastructure

## Overview
Hybrid infrastructure-as-code workflow combining NixOS system management with Docker service deployment on the HL15 homelab server. NixOS handles system-level configuration (users, groups, permissions, directories) while Docker Compose manages application services. Just provides declarative dependency management and deployment automation.

## Repository Structure

### Repository Structure (Infrastructure as Code)
```
homelab/                          # Git repository at /opt/homelab/
├── CLAUDE.md
├── .gitignore
├── Justfile                      # Declarative deployment automation
├── docs/
│   └── ... documentation and planning files ...
├── nixos/
│   ├── modules/
│   │   ├── services/
│   │   │   └── [service]/user.nix    # Individual service user configs
│   │   ├── groups/
│   │   │   └── [group]/[group].nix   # Domain group definitions
│   │   └── default.nix               # Module imports
│   ├── ... other NixOS system configuration files ...
│   └── users/
│       └── ... Human user account configuration files ...
└── services/
    ├── README.template.md
    └── [service]/
        ├── README.md
        ├── compose.yml               # Standard Docker Compose
        ├── .env                      # Actual secrets (gitignored)
        └── .env.example              # Template (committed)
```

### Runtime Data Structure (Service State)
```
/var/lib/services/                # Service runtime data (separate from repo)
├── [service]/                    # Single-instance services
│   └── ... service manages its own files/directories ...
└── [service]/                    # Multi-instance services
    └── [instance]/               # Instance-specific data
        └── ... service manages its own files/directories ...
```

**Note:** Each service has full control over its runtime directory structure. Services will organize their config files, databases, logs, and cache however they need internally. Using `/var/lib/services/` follows Linux filesystem hierarchy standards for variable service data.

## Server Setup (One-Time Configuration)

### Initial Repository Deployment
```bash
# Clone repository to standard location on server
sudo git clone https://github.com/username/homelab.git /opt/homelab

# Create symbolic link for NixOS configs only
sudo ln -sf /opt/homelab/nixos /etc/nixos

# Configure git for safe directory access
cd /opt/homelab
sudo git config --global --add safe.directory /opt/homelab

# Create runtime data directory structure
sudo mkdir -p /var/lib/services
sudo chown -R admin:admin /var/lib/services

# Set proper permissions for service directories
sudo chown -R admin:admin /opt/homelab/services
sudo chmod 700 /opt/homelab/services/**/.env  # Protect actual secrets
```

### Environment File Setup
```bash
# For each service, copy example to actual environment file
sudo cp /opt/homelab/services/sonarr/shows/.env.example /opt/homelab/services/sonarr/shows/.env
sudo cp /opt/homelab/services/sonarr/anime/.env.example /opt/homelab/services/sonarr/anime/.env
sudo cp /opt/homelab/services/radarr/movies/.env.example /opt/homelab/services/radarr/movies/.env
sudo cp /opt/homelab/services/radarr/anime/.env.example /opt/homelab/services/radarr/anime/.env
sudo cp /opt/homelab/services/plex/.env.example /opt/homelab/services/plex/.env

# Edit each .env file with actual secrets and configuration
sudo nano /opt/homelab/services/sonarr/shows/.env
sudo nano /opt/homelab/services/sonarr/anime/.env
sudo nano /opt/homelab/services/radarr/movies/.env
sudo nano /opt/homelab/services/radarr/anime/.env
sudo nano /opt/homelab/services/plex/.env
```

### Runtime Data Directory Creation
```bash
# NixOS modules will handle this automatically, but for reference:
# Service runtime directories are created at:
# /var/lib/services/[service]/          # Single-instance services
# /var/lib/services/[service]/[instance]/ # Multi-instance services (sonarr, radarr)

# Each service has full ownership of its directory and manages:
# - Internal file/directory organization
# - Configuration files and databases
# - Logs and temporary files
# - Any other service-specific data

# Using /var/lib/services/ follows Linux FHS for variable service data
```

## Git Configuration for Public Repository

### .gitignore Configuration
```gitignore
# Nix/NixOS
result
result-*
.direnv/

# Flakes (keeping flake.lock in version control for reproducibility)

# Temporary files
*~
*.tmp
*.temp

# Log files
*.log

# OS-specific
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo

# Local environment files
.env
.env.local

# Environment files with secrets
services/**/.env
*.env

# But allow example files
!*.env.example

# Backup files
*.backup
*.bak

# Network testing output (keep directory structure, ignore contents)
network-testing/*.log
network-testing/bond0

# Documentation artifacts
*.pdf
```

### Environment File Templates
Each service directory includes:
- **`.env.example`** - Template with placeholder values (committed to git)
- **`.env`** - Actual secrets and configuration (gitignored)

Example `.env.example` for Sonarr:
```bash
# Sonarr Configuration
SONARR_API_KEY=your_api_key_here
SONARR_PORT=8989
SONARR_URL_BASE=/sonarr

# User/Group IDs
PUID=1000
PGID=1000

# Timezone
TZ=America/Los_Angeles

# Storage Paths (adjust for your ZFS vault structure)
MEDIA_PATH=/mnt/vault/media/shows
DOWNLOAD_PATH=/mnt/vault/temp/downloads

# Database Configuration
DB_PASSWORD=secure_password_here
DB_NAME=sonarr_main

# Network Configuration
NETWORK_NAME=homelab_network
```

## Deployment Automation with Justfile

### Hybrid Deployment Strategy
The Justfile implements a declarative dependency system where each service has an `ensure-[service]` recipe that:
1. Ensures all dependencies are running first
2. Starts the service itself
3. Provides idempotent operations (safe to run multiple times)

### Justfile Structure
```just
# Default recipe
default:
    @just --list

# Update system and all services
deploy-all: update-system
    @echo "Deploying all services with proper dependency order..."
    @just ensure-plex ensure-sonarr-shows ensure-sonarr-anime ensure-radarr-movies ensure-overseerr
    @echo "Full deployment complete!"

# Update NixOS configuration only (handles users, groups, permissions)
update-system:
    @echo "Updating NixOS system configuration..."
    git pull
    nixos-rebuild switch

# Infrastructure services (foundational)
ensure-gluetun:
    @echo "Ensuring gluetun VPN gateway is running..."
    cd services/gluetun && docker compose up -d

ensure-pihole:
    @echo "Ensuring pihole DNS is running..."
    cd services/pihole && docker compose up -d

# Media pipeline dependencies
ensure-prowlarr: ensure-gluetun
    @echo "Ensuring prowlarr indexer management is running..."
    cd services/prowlarr && docker compose up -d

ensure-deluge: ensure-gluetun
    @echo "Ensuring deluge torrent client is running..."
    cd services/deluge && docker compose up -d

ensure-tdarr: ensure-deluge
    @echo "Ensuring tdarr transcoding is running..."
    cd services/tdarr && docker compose up -d

ensure-profilarr: ensure-prowlarr
    @echo "Ensuring profilarr quality management is running..."
    cd services/profilarr && docker compose up -d

# Content management services
ensure-sonarr-shows: ensure-prowlarr ensure-tdarr ensure-profilarr
    @echo "Ensuring sonarr TV shows is running..."
    cd services/sonarr/shows && docker compose up -d

ensure-sonarr-anime: ensure-prowlarr ensure-tdarr ensure-profilarr
    @echo "Ensuring sonarr anime shows is running..."
    cd services/sonarr/anime && docker compose up -d

ensure-radarr-movies: ensure-prowlarr ensure-tdarr ensure-profilarr
    @echo "Ensuring radarr movies is running..."
    cd services/radarr/movies && docker compose up -d

ensure-radarr-anime: ensure-prowlarr ensure-tdarr ensure-profilarr
    @echo "Ensuring radarr anime movies is running..."
    cd services/radarr/anime && docker compose up -d

ensure-overseerr: ensure-sonarr-shows ensure-sonarr-anime ensure-radarr-movies ensure-radarr-anime
    @echo "Ensuring overseerr media requests is running..."
    cd services/overseerr && docker compose up -d

# Media server (end of pipeline)
ensure-plex: ensure-tdarr
    @echo "Ensuring plex media server is running..."
    cd services/plex && docker compose up -d

# Observability services
ensure-alloy:
    @echo "Ensuring alloy telemetry collection is running..."
    cd services/alloy && docker compose up -d

ensure-loki: ensure-alloy
    @echo "Ensuring loki log aggregation is running..."
    cd services/loki && docker compose up -d

ensure-prometheus: ensure-alloy
    @echo "Ensuring prometheus metrics is running..."
    cd services/prometheus && docker compose up -d

ensure-grafana: ensure-loki ensure-prometheus
    @echo "Ensuring grafana dashboards is running..."
    cd services/grafana && docker compose up -d

ensure-homepage:
    @echo "Ensuring homepage admin dashboard is running..."
    cd services/homepage && docker compose up -d

# Self-hosting services
ensure-immich:
    @echo "Ensuring immich photo management is running..."
    cd services/immich && docker compose up -d

ensure-nextcloud:
    @echo "Ensuring nextcloud file sync is running..."
    cd services/nextcloud && docker compose up -d

# User-facing deployment commands
deploy service: update-system
    @echo "Deploying service: {{service}}"
    git pull
    @just ensure-{{service}}

# Service group deployments
deploy-media: update-system
    @echo "Deploying media pipeline services..."
    git pull
    @just ensure-plex ensure-sonarr-shows ensure-sonarr-anime ensure-radarr-movies ensure-radarr-anime ensure-overseerr

deploy-monitoring: update-system
    @echo "Deploying observability services..."
    git pull
    @just ensure-grafana ensure-homepage

deploy-infrastructure: update-system
    @echo "Deploying infrastructure services..."
    git pull
    @just ensure-gluetun ensure-pihole ensure-homepage

deploy-selfhosting: update-system
    @echo "Deploying self-hosting services..."
    git pull
    @just ensure-immich ensure-nextcloud

# Service management commands
stop service:
    @echo "Stopping service: {{service}}"
    #!/usr/bin/env bash
    if [[ "{{service}}" == sonarr-* ]]; then
        instance=${service#sonarr-}
        cd services/sonarr/$instance && docker compose down
    elif [[ "{{service}}" == radarr-* ]]; then
        instance=${service#radarr-}
        cd services/radarr/$instance && docker compose down
    else
        cd services/{{service}} && docker compose down
    fi

restart service:
    @echo "Restarting service: {{service}}"
    @just stop {{service}}
    @just ensure-{{service}}

logs service:
    @echo "Showing logs for service: {{service}}"
    #!/usr/bin/env bash
    if [[ "{{service}}" == sonarr-* ]]; then
        instance=${service#sonarr-}
        cd services/sonarr/$instance && docker compose logs -f
    elif [[ "{{service}}" == radarr-* ]]; then
        instance=${service#radarr-}
        cd services/radarr/$instance && docker compose logs -f
    else
        cd services/{{service}} && docker compose logs -f
    fi

# Pull latest images for all services
pull-images:
    @echo "Pulling latest images for all services..."
    #!/usr/bin/env bash
    for dir in services/*/; do
        if [ -f "$dir/compose.yml" ]; then
            echo "Pulling images for $dir"
            cd "$dir" && docker compose pull
            cd - > /dev/null
        fi
    done
    # Handle nested service directories (sonarr/radarr instances)
    for dir in services/sonarr/*/ services/radarr/*/; do
        if [ -f "$dir/compose.yml" ]; then
            echo "Pulling images for $dir"
            cd "$dir" && docker compose pull
            cd - > /dev/null
        fi
    done

# Clean up unused Docker resources
cleanup:
    @echo "Cleaning up unused Docker resources..."
    docker system prune -f
    docker image prune -f

# Validate all compose files
validate:
    @echo "Validating all Docker Compose files..."
    #!/usr/bin/env bash
    for dir in services/*/; do
        if [ -f "$dir/compose.yml" ]; then
            echo "Validating $dir/compose.yml"
            cd "$dir" && docker compose config > /dev/null
            cd - > /dev/null
        fi
    done
    # Handle nested service directories
    for dir in services/sonarr/*/ services/radarr/*/; do
        if [ -f "$dir/compose.yml" ]; then
            echo "Validating $dir/compose.yml"
            cd "$dir" && docker compose config > /dev/null
            cd - > /dev/null
        fi
    done
```

## Development Workflow

### Local Development (on development machine)
```bash
# Make changes to configurations
vim nixos/configuration.nix
vim services/sonarr/shows/compose.yml

# Test NixOS changes locally (if using NixOS on dev machine)
nixos-rebuild dry-build --flake ./nixos#homelab-hl15

# Validate flake syntax and configuration
nix flake check ./nixos

# Test Docker Compose configurations
docker compose -f services/sonarr/shows/compose.yml config
docker compose -f services/sonarr/anime/compose.yml config
docker compose -f services/radarr/movies/compose.yml config
docker compose -f services/radarr/anime/compose.yml config

# Commit and push changes
git add .
git commit -m "Update Sonarr configuration for new media library structure"
git push origin main
```

### Server Deployment Workflows

#### System Configuration Updates
```bash
# SSH to server
ssh admin@homelab-hl15

# Navigate to homelab directory
cd /opt/homelab

# Deploy system changes only (requires sudo for nixos-rebuild)
sudo just update-system
```

#### Service Configuration Updates
```bash
# SSH to server
ssh admin@homelab-hl15

# Navigate to homelab directory
cd /opt/homelab

# Deploy all services (no sudo needed - admin is in docker group)
just update-services

# Or deploy specific service group
just deploy-media

# Or deploy individual service
just deploy plex

# Or deploy specific Sonarr instance
just deploy-sonarr shows
just deploy-sonarr anime

# Or deploy specific Radarr instance
just deploy-radarr movies
just deploy-radarr anime
```

#### Full Infrastructure Update
```bash
# SSH to server
ssh admin@homelab-hl15

# Navigate to homelab directory
cd /opt/homelab

# Deploy everything (sudo only needed for system portion)
sudo just deploy-all
```

### Emergency Procedures

#### Rollback System Configuration
```bash
cd /opt/homelab
git log --oneline  # View recent commits
git checkout HEAD~1  # Roll back one commit
sudo just update-system  # Only sudo for nixos-rebuild
```

#### Rollback Service Configuration
```bash
cd /opt/homelab
git checkout HEAD~1
just deploy SERVICE_NAME  # No sudo needed

# Or rollback specific service only
cd /opt/homelab/services/SERVICE_NAME
git checkout HEAD~1 -- .
docker compose up -d --remove-orphans  # No sudo needed
```

#### Check Service Status
```bash
# View logs for specific service
just logs plex

# View logs for Sonarr instance
just logs-sonarr shows

# Check all running containers
docker ps

# Check service health
cd /opt/homelab/services/SERVICE_NAME
docker compose ps

# Validate all compose files
just validate
```

## Security Considerations

### Secret Management
- **Never commit .env files** - Always gitignored
- **Use .env.example templates** - Document required variables without exposing secrets
- **Proper file permissions** - .env files should be 600 (owner read/write only)
- **Regular secret rotation** - Update API keys and passwords periodically

### Access Control
- **Admin user required** - All deployment commands require sudo/admin privileges
- **SSH key authentication** - Use key-based auth for server access
- **Git repository access** - Control who can push to the repository

### Backup Strategy
- **Configuration in git** - All configurations version controlled
- **Secret backup separate** - .env files backed up outside of git
- **ZFS snapshots** - System automatically snapshots configuration changes

## Monitoring and Maintenance

### Regular Tasks
```bash
# Weekly: Update all services to latest images
just pull-images
just update-services

# Monthly: Clean up unused Docker resources
just cleanup

# As needed: Check service logs
just logs SERVICE_NAME
just logs-sonarr shows

# Validate configurations before deployment
just validate
```

### Health Checks
```bash
# System health
sudo systemctl status
sudo zpool status vault

# Service health
sudo docker ps
sudo docker stats

# Network connectivity
ping -c 3 8.8.8.8
```

## Benefits of This Workflow

### Development Experience
- **Infrastructure as Code** - All configurations version controlled
- **Rapid iteration** - Quick deploy/test/rollback cycles
- **Documentation** - Git history shows what changed and when
- **Collaboration ready** - Public repo enables community contributions

### Operational Benefits
- **Consistent deployments** - Same process every time
- **Atomic updates** - Services update together or not at all
- **Easy rollbacks** - Git-based rollback to any previous state
- **Selective deployment** - Update individual services or groups

### Security Benefits
- **No secrets in git** - Public repository safe with proper .gitignore
- **Audit trail** - All changes tracked in git history
- **Access control** - Deployment requires server admin privileges
- **Secret isolation** - Each service has isolated environment

## Future Enhancements

### Potential Improvements
- **Pre-deployment testing** - Automated validation before deployment
- **Health checks** - Automated service health verification post-deployment
- **Notifications** - Discord/email notifications for deployment status
- **Staging environment** - Test changes before production deployment
- **Secrets management** - Integration with external secret stores

### Scaling Considerations
- **Multiple environments** - Support dev/staging/prod environments
- **Service dependencies** - Manage startup order and dependencies
- **Load balancing** - Multiple service instances for high availability
- **Monitoring integration** - Automated alerting and metrics collection

## Success Criteria

- [ ] Repository structure implemented and organized
- [ ] Symbolic links created on server (/etc/nixos → /opt/homelab/nixos)
- [ ] .gitignore properly configured to exclude secrets
- [ ] .env.example files created for all services
- [ ] Justfile deployment targets working
- [ ] NixOS updates deployable via `just update-system`
- [ ] Service updates deployable via `just update-services`
- [ ] Individual service deployment working
- [ ] Rollback procedures tested and documented
- [ ] Secret management workflow established