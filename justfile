# Default recipe - show available commands
default:
    just --list

# repo-related commands
pull:
    git fetch
    git pull

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

# Homepage Configuration Management

# Sync homepage configs to service directory and restart service
hp-up:
    sudo rsync -av /opt/homelab/homepage/ /var/lib/services/homepage/
    sudo chown -R homepage:services /var/lib/services/homepage/
    sudo systemctl restart homepage
    @echo "Homepage configuration synced and service restarted"