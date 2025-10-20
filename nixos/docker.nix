{ config, pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;

    # Use rootful Docker for homelab (better networking, performance)
    # Rootless disabled - this is a single-user server, not a shared system

    # Configure Docker daemon with proper DNS
    daemon.settings = {
      # Use Cloudflare DNS for containers (reliable, fast)
      dns = [ "1.1.1.1" "1.0.0.1" ];

      # Fallback to Google DNS if Cloudflare is unavailable
      # dns = [ "8.8.8.8" "8.8.4.4" ];
    };
  };
}