{ config, lib, pkgs, ... }:

{
    users.groups = {
        # Group for all homelab services
        # Useful for system-wide permissions
        services = {};

        # Shared media access group
        # All services that read/write media files should be part of this group
        # Such as: deluge, sonarr, radarr, tdarr, plex, etc.
        media = {};

        # VPN access group
        # Services that require VPN access should be part of this group
        # Note: This group does not enforce routing itself,
        # as that is handled by systemd slices and cgroups.
        # Instead it is simply for organization, auditing and clarity.
        vpn = {};

        # Group for video/audio transcoding services
        # Services that perform media transcoding should be part of this group
        # Useful for granting GPU access to services like Plex and Tdarr
        transcode = {};
    };
}