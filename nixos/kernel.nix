# Kernel Configuration
# Additional kernel modules and parameters for homelab services

{ config, lib, pkgs, ... }:

{
  # Load TUN/TAP module for VPN support (Gluetun)
  boot.kernelModules = [ "tun" ];

  # Ensure /dev/net/tun is available
  boot.kernel.sysctl = {
    # Already set in gluetun compose, but good to have at system level too
    "net.ipv4.conf.all.src_valid_mark" = 1;
  };
}
