# Cloudflared Tunnel Service Configuration
# Manages Cloudflare Zero Trust tunnel for remote access to homelab services

{ config, lib, pkgs, ... }:

{
  # Enable cloudflared tunnel service
  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "admin";
      Group = "users";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /home/admin/.cloudflared/config.yml run homelab-immich";
      Restart = "always";
      RestartSec = 10;
      
      # Security settings
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = "/home/admin/.cloudflared";
    };
  };
}