{ config, lib, pkgs, ... }:

{
  # Admin user for homelab system administration
  users.users.admin = {
    isNormalUser = true;
    description = "Homelab Administrator";
    uid = 1001;
    extraGroups = [
      "wheel"           # Sudo access
      "docker"          # Docker daemon access
      "service"         # Service group access
      "systemd-journal" # System log access
    ];
    packages = with pkgs; [
      htop              # System monitoring
      docker            # Docker CLI (includes compose)
      git               # Version control
      just              # Command runner for deployment
      zfs               # ZFS utilities
      tree              # Directory structure viewing
      curl              # HTTP client
      wget              # File downloading
      vim               # Text editor
      gh                # GitHub CLI
      jq                # JSON processor
    ];
    shell = pkgs.bash;  # Default shell
  };
}