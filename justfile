# NixOS System Management Commands

# Test system configuration changes (dry-run)
sys-up-test:
    sudo nixos-rebuild dry-activate --flake /etc/nixos#homelab-hl15

# Deploy system configuration changes
sys-up:
    sudo nixos-rebuild switch --flake /etc/nixos#homelab-hl15

# Rollback to previous system generation
sys-down:
    sudo nixos-rebuild switch --rollback

# Docker Service Management Commands

# Infrastructure services (foundational)
ensure-gluetun:
    ./scripts/ensure-service.sh gluetun services/gluetun