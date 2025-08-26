# Services Base Group Module
# Logical grouping for all homelab service users
# Provides foundation for future service-wide permissions if needed

{ config, lib, pkgs, ... }:

{
  users.groups.services = {
    gid = 3000;  # Base GID for all service users
    # No members list - services join this group individually via group = "services"
    # No directory creation - this is just logical grouping for now
  };
}