{ config, lib, pkgs, ... }:

{
    systemd.slices."vpn.slice" = {
        Description = "Slice for VPN-isolated services";

        # Resource limits
        CPUAccounting = true;
        MemoryAccounting = true;
        IOAccounting = true;
    };
}