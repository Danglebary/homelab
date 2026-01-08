{ config, lib, pkgs, ... }:

{
    users.users = {
        admin = {
            isNormalUser = true;
            description = "Homelab Administrator";
            
            extraGroups = [
                "wheel" # Sudo access
                "media" # Media management group
            ];

            packages = with pkgs; [
                htop
                git
                just
                zfs
                tree
                curl
                wget
                vim
                gh
                jq
            ];

            shell = pkgs.bash;
        };

        deluge = {
            isSystemUser = true;
            description = "Deluge service user account";

            group = "services";
            extraGroups = [ "vpn" "media" ];

            home = "/var/lib/services/deluge";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        prowlarr = {
            isSystemUser = true;
            description = "Prowlarr service user account";

            group = "services";
            extraGroups = [ "vpn" ];

            home = "/var/lib/services/prowlarr";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        radarr = {
            isSystemUser = true;
            description = "Radarr service user account";

            group = "services";
            extraGroups = [ "vpn" "media" ];

            home = "/var/lib/services/radarr";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        sonarr = {
            isSystemUser = true;
            description = "Sonarr service user account";

            group = "services";
            extraGroups = [ "vpn" "media" ];

            home = "/var/lib/services/sonarr";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        plex = {
            isSystemUser = true;
            description = "Plex service user account";

            group = "services";
            extraGroups = [ "media" "transcode" ];

            home = "/var/lib/services/plex";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        tdarr = {
            isSystemUser = true;
            description = "Tdarr service user account";

            group = "services";
            extraGroups = [ "media" "transcode" ];

            home = "/var/lib/services/tdarr";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        overseerr = {
            isSystemUser = true;
            description = "Overseerr service user account";

            group = "services";
            extraGroups = [];

            home = "/var/lib/services/overseerr";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        immich = {
            isSystemUser = true;
            description = "Immich service user account";

            group = "services";
            extraGroups = [];

            home = "/var/lib/services/immich";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };

        cloudflared = {
            isSystemUser = true;
            description = "Cloudflared service user account";

            group = "services";
            extraGroups = [];

            home = "/var/lib/services/cloudflared";
            createHome = true;
            shell = pkgs.shadow.runAsShell;
        };
    };
}