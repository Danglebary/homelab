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

# Docker Service Management Commands

# Infrastructure services (foundational)
ensure-gluetun:
    ./scripts/ensure-service.sh gluetun services/gluetun