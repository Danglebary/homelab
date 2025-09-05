# Deluge Service User Module
# BitTorrent client with VPN isolation
# Downloads files to temp processing directories

{ config, lib, pkgs, ... }:

{
  users.users.deluge = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "downloads" ];
    uid = 2020;  # Consistent UID for Docker containers
    home = "/var/lib/services/deluge";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (deluge manages internal structure)
    "d /var/lib/services/deluge 0755 deluge services -"
    
    # Service logging directory for local log storage
    "d /var/log/services/deluge 0755 deluge services -"
  ];
}