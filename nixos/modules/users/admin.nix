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
      "services"        # Base service group
      "anime"           # Anime media access
      "shows"           # TV shows media access  
      "movies"          # Movies media access
      "downloads"       # Download processing access
      "transcoding"     # Transcoding processing access
      "cleanup"         # Maintenance cleanup access
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
    ];
    shell = pkgs.bash;  # Default shell
  };
}