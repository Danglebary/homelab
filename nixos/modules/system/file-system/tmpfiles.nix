{ config, lib, pkgs, ... }:

{
    systemd.tmpfiles.rules = [
        # Services top-level runtime db/config directory
        "d /var/lib/services 2775 root services -"

        # Immich - photo/video storage
        "d /mnt/vault/immich 2775 immich immich -"

        # Media directories (Radarr, Sonarr, Plex, Tdarr, etc.)
        "d /mnt/vault/media 2775 root media -"
        "d /mnt/vault/media/anime 2775 root media -"
        "d /mnt/vault/media/movies 2775 root media -"
        "d /mnt/vault/media/shows 2775 root media -"


        # Download directories (for deluge)
        "d /mnt/vault/downloads 2775 root media -"
        "d /mnt/vault/downloads/incomplete 2775 root media -"
        "d /mnt/vault/downloads/complete 2775 root media -"
        "d /mnt/vault/downloads/complete/anime 2775 root media -"
        "d /mnt/vault/downloads/complete/movies 2775 root media -"
        "d /mnt/vault/downloads/complete/shows 2775 root media -"
    ];
}