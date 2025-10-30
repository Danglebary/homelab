# Default recipe - show available commands
default:
    just --list

# NixOS System Management Commands

# Sync nixos configuration from repo to system location
sync-nixos:
    sudo rsync -av --delete /opt/homelab/nixos/ /etc/nixos/

# Test system configuration changes (dry-run)
sys-up-test: sync-nixos
    sudo nixos-rebuild dry-activate --flake /etc/nixos#homelab-hl15

# Deploy system configuration changes
sys-up: sync-nixos
    sudo nixos-rebuild switch --flake /etc/nixos#homelab-hl15

# Rollback to previous system generation
sys-down:
    sudo nixos-rebuild switch --rollback

# Force file structures to be created
sys-fs-create:
    sudo systemd-tmpfiles --create

# Docker Service Management Commands

# Start/stop all Docker services
docker-up:
    just gluetun-up
    just immich-up
    just plex-up
docker-down:
    just immich-down
    just gluetun-down
    just plex-down

# Infrastructure services
gluetun-up:
    ./scripts/start-service.sh gluetun
gluetun-down:
    ./scripts/stop-service.sh gluetun

# Self-hosting services

immich-up:
    ./scripts/start-service.sh immich
immich-down:
    ./scripts/stop-service.sh immich

# Media services

plex-up:
    ./scripts/start-service.sh plex
plex-down:
    ./scripts/stop-service.sh plex