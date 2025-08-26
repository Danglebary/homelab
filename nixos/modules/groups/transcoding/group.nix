# Transcoding Processing Group Module
# Controls transcoded files directory for media processing pipeline

{ config, lib, pkgs, ... }:

{
  users.groups.transcoding = {
    gid = 3021;  # Transcoding processing group
  };

  # Create transcoding directories with proper permissions
  systemd.tmpfiles.rules = [
    # Transcoded files directory (setgid bit ensures group inheritance)
    "d /mnt/vault/transcoded 2775 root transcoding -"
  ];
}