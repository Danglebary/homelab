{ config, lib, pkgs, ... }:

{
    # Service group for all homelab services
    users.groups.service = {
        gid = 3000;
    };
}