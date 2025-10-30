{ config, lib, pkgs, ... }:

{
    # Load TUN/TAP module for VPN support
    boot.kernelModules = [ "tun" ];

    # Ensure /dev/net/tun is available
    boot.kernel.sysctl = {
        "net.ipv4.conf.all.src_valid_mark" = 1;
    };
}
