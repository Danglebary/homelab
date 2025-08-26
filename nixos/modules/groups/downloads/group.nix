# Downloads Processing Group Module
# Controls download directory access for torrent and download management

{ config, lib, pkgs, ... }:

{
  users.groups.downloads = {
    gid = 3020;  # Downloads processing group
  };

  # Create download directories with proper permissions
  systemd.tmpfiles.rules = [
    # Download processing directories (setgid bit ensures group inheritance)
    "d /mnt/vault/temp/downloads 2775 root downloads -"
    "d /mnt/vault/temp/downloads/pending 2775 root downloads -"
    "d /mnt/vault/temp/downloads/completed 2775 root downloads -"
  ];
}