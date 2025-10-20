# Service User Module
# Single consolidated user for all homelab services
# Used by all Docker containers via PUID/PGID or user: directive

{ config, lib, pkgs, ... }:

{
  users.users.service = {
    uid = 2000;
    group = "service";
    isSystemUser = true;
    home = "/var/lib/services";
    createHome = true;
    description = "Homelab services user";
  };
}
