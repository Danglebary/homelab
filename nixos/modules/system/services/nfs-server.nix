{ config, lib, pkgs, ... }:

{
    # Enable NFS server
    services.nfs.server.enable = true;

    # Define exports
    services.nfs.server.exports = ''
      /mnt/vault 192.168.68.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1001,anongid=3000)
    '';

    # Open firewall for NFS
    networking.firewall.allowedTCPPorts = [ 111 2049 20048 ];
    networking.firewall.allowedUDPPorts = [ 111 2049 20048 ];
}