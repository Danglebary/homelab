{ config, lib, pkgs, ... }:

{
    systemd.slices."vpn" = {
        description = "Slice for VPN-isolated services";

        sliceConfig = {
            # Enable resource accounting
            CPUAccounting = true;
            MemoryAccounting = true;
            IOAccounting = true;
        };
    };
}