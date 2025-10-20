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

      # Prevent Docker from auto-detecting and using wrong resolver
      # Force it to use our explicit DNS settings
      iptables = true;

      # Use default bridge network with our DNS
      bridge = "docker0";
    };
  };
}