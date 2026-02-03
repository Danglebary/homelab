# TODO list

This is a list of tasks/features I'd like to implement to improve this project:
- [ ] Install GPU and setup hardware acceleration for Plex
- [ ] NUT + WOL/NUT:
  - Integrate Wake-on-LAN functionality with Network UPS Tools (NUT) for automated power management of the rack UPS.
  - This will allow the server to automatically gracefully shut down during power outages, and wake up when power is restored.
  - Likely run both NUT and WOL/NUT on dedicated rPI rather than on the main server due to power considerations.
- [ ] eBook and Audiobook aquisition and management:
    - Currently waiting for LazyLibrarian NixOS PR to be merged
    - Setup LazyLibrarian for automated eBook and Audiobook downloading and management.
    - Setup Calibre-Web and/or Audiobookshelf for eBook library management and access.
- [ ] Setup Home Assistant
- [ ] Setup observability stack (Prometheus + Grafana)
    - Service-level monitoring
    - System-level monitoring (CPU, GPU, RAM, Disk, Network, VPN, Tunnel, UPS, etc.)
    - Alerting (webhooks, email, discord, etc.)
- [ ] Setup automated transcoding for media files
    - Something like tdarr could work, but may be too complicated for my needs
    - Possibly just simple ffmpeg automation
    - If I could transcode my media to HLS at-rest and serve that directly via plex, that would be ideal
    - Have to take into account seeding requirements for torrents, can't immediately transcode and delete source files if they are still being seeded
- [ ] Setup immich for photo/video backup and management
- [ ] Setup nextcloud or similar for general file storage/backup and sync