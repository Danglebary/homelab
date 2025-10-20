{ config, pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;

    # Use rootful Docker for homelab (better networking, performance)
    # Rootless disabled - this is a single-user server, not a shared system
  };
}