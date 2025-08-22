{ config, lib, pkgs, ... }:

{
  # Enable ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "vault" ];

  # ZFS kernel module settings
  boot.kernelParams = [
    # Set ZFS ARC cache limits for 256GB RAM system
    "zfs.zfs_arc_max=137438953472"  # 128GB max
    "zfs.zfs_arc_min=68719476736"   # 64GB min
  ];

  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      pools = [ "vault" ];
    };
    autoSnapshot = {
      enable = true;
      frequent = 8;    # 15-minute snapshots, keep 8 (2 hours)
      hourly = 24;     # Hourly snapshots, keep 24
      daily = 7;       # Daily snapshots, keep 7
      weekly = 4;      # Weekly snapshots, keep 4
      monthly = 6;     # Monthly snapshots, keep 6
    };
  };

  # Mount vault pool
  fileSystems."/mnt/vault" = {
    device = "vault";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # Create basic directory structure (Phase 1)
  systemd.tmpfiles.rules = [
    # Main dataset directories
    "d /mnt/vault/system 0755 root root -"
    "d /mnt/vault/users 0755 root root -"
    "d /mnt/vault/media 0755 root root -"
    "d /mnt/vault/temp 0755 root root -"
  ];
}