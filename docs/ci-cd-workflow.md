# CI/CD Workflow for Homelab Infrastructure

## Overview
Git-based infrastructure-as-code workflow for managing both NixOS system configuration and Docker service deployments on the HL15 homelab server. This workflow enables rapid, consistent deployments while maintaining security through proper secret management.

## Repository Structure

### Current Structure
```
homelab/
├── CLAUDE.md
├── .gitignore
├── Justfile                      # Deployment automation
├── docs/
│   └── ... documentation and planning files ...
├── nixos/
│   ├── ... NixOS modular system configuration files ...
│   └── users/
│       └── ... User account configuration files ...
└── services/
    ├── README.template.md
    └── [service]/
        ├── README.md
        ├── compose.yml
        ├── .env
        ├── .env.example
        └── ... additional service-related configs/data ...
```

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

### Justfile Structure
```just
# Default recipe
default:
    @just --list

# Update system and all services
deploy-all: update-system update-services
    @echo "Full deployment complete!"

# Update NixOS configuration only
update-system:
    @echo "Updating NixOS system configuration..."
    git pull
    nixos-rebuild switch

# Update all Docker services only
update-services:
    @echo "Updating all Docker services..."
    git pull
    #!/usr/bin/env bash
    for dir in services/*/; do
        if [ -f "$dir/compose.yml" ]; then
            echo "Updating service in $dir"
            cd "$dir" && docker compose up -d --remove-orphans
            cd - > /dev/null
        fi
    done

# Update media services (Plex, Sonarr, Radarr, Overseerr)
deploy-media:
    @echo "Deploying media services..."
    git pull
    cd services/plex && docker compose up -d --remove-orphans
    cd services/sonarr/shows && docker compose up -d --remove-orphans
    cd services/sonarr/anime && docker compose up -d --remove-orphans
    cd services/radarr/movies && docker compose up -d --remove-orphans
    cd services/radarr/anime && docker compose up -d --remove-orphans
    cd services/overseerr && docker compose up -d --remove-orphans
    cd services/tdarr && docker compose up -d --remove-orphans

# Update monitoring services
deploy-monitoring:
    @echo "Deploying monitoring services..."
    git pull
    cd services/uptime-kuma && docker compose up -d --remove-orphans
    cd services/prometheus && docker compose up -d --remove-orphans
    cd services/grafana && docker compose up -d --remove-orphans
    cd services/homepage && docker compose up -d --remove-orphans

# Deploy specific service
deploy SERVICE:
    @echo "Deploying service: {{SERVICE}}"
    git pull
    cd services/{{SERVICE}} && docker compose up -d --remove-orphans

# Deploy specific Sonarr instance (shows or anime)
deploy-sonarr INSTANCE:
    @echo "Deploying Sonarr {{INSTANCE}} instance"
    git pull
    cd services/sonarr/{{INSTANCE}} && docker compose up -d --remove-orphans

# Deploy specific Radarr instance 
deploy-radarr INSTANCE:
    @echo "Deploying Radarr {{INSTANCE}} instance"
    git pull
    cd services/radarr/{{INSTANCE}} && docker compose up -d --remove-orphans

# Stop specific service
stop SERVICE:
    @echo "Stopping service: {{SERVICE}}"
    cd services/{{SERVICE}} && docker compose down

# Stop specific Sonarr instance
stop-sonarr INSTANCE:
    @echo "Stopping Sonarr {{INSTANCE}} instance"
    cd services/sonarr/{{INSTANCE}} && docker compose down

# Stop specific Radarr instance
stop-radarr INSTANCE:
    @echo "Stopping Radarr {{INSTANCE}} instance"
    cd services/radarr/{{INSTANCE}} && docker compose down

# Restart specific service
restart SERVICE:
    @echo "Restarting service: {{SERVICE}}"
    cd services/{{SERVICE}} && docker compose down && docker compose up -d --remove-orphans

# Show logs for specific service
logs SERVICE:
    @echo "Showing logs for service: {{SERVICE}}"
    cd services/{{SERVICE}} && docker compose logs -f

# Show logs for specific Sonarr instance
logs-sonarr INSTANCE:
    @echo "Showing logs for Sonarr {{INSTANCE}} instance"
    cd services/sonarr/{{INSTANCE}} && docker compose logs -f

# Show logs for specific Radarr instance
logs-radarr INSTANCE:
    @echo "Showing logs for Radarr {{INSTANCE}} instance"
    cd services/radarr/{{INSTANCE}} && docker compose logs -f

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