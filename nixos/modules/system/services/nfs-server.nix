{ config, lib, pkgs, ... }:

{
    # Enable NFS server
    services.nfs.server.enable = true;

    # Define exports
    services.nfs.server.exports = ''
      /mnt/vault 192.168.68.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=3000)
    '';

    # Open firewall for NFS
    networking.firewall.allowedTCPPorts = [ 2049 ];
    networking.firewall.allowedUDPPorts = [ 2049 ];
}