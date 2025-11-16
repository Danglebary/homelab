{ config, lib, pkgs, ... }:

{
    systemd.tmpfiles.rules = [
        # Immich - runtime directories
        "d /var/lib/services/immich 2775 service service -"
        "d /var/lib/services/immich/ml-cache 2775 service service -"

        # Immich - photo/video storage
        "d /mnt/vault/immich 2775 service service -"

        # Actual - budgeting app server
        "d /mnt/vault/services/actual_budget 2775 service service -"

        # Plex - runtime directories
        "d /var/lib/services/plex 2775 service service -"

        # Prowlarr - runtime directories
        "d /var/lib/services/prowlarr 2775 service service -"

        # Media directories (Radarr, Sonarr, Plex, Tdarr, etc.)
        "d /mnt/vault/media/anime 2775 service service -"
        "d /mnt/vault/media/movies 2775 service service -"
        "d /mnt/vault/media/shows 2775 service service -"

        # Processing directories (deluge, Tdarr, etc.)
        "d /mnt/vault/downloads 2775 service service -"

        "d /mnt/vault/downloads/incomplete 2775 service service -"

        "d /mnt/vault/downloads/complete 2775 service service -"
        "d /mnt/vault/downloads/complete/anime 2775 service service -"
        "d /mnt/vault/downloads/complete/movies 2775 service service -"
        "d /mnt/vault/downloads/complete/shows 2775 service service -"
    ];
}