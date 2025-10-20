# Gluetun Directory Setup
# Creates required directories for Gluetun VPN container
# Gluetun runs as root and needs write access for server lists and state

{ config, lib, pkgs, ... }:

{
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Gluetun state directory (root owned since container runs as root)
    "d /var/lib/services/gluetun 0755 root root -"
  ];
}
