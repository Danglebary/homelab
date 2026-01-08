# 🗺️ Homelab Reference Map

## 1️⃣ Directory Layout

| Path                                   | Purpose                                   | Owner         | Group      | Permissions / Notes                          |
| -------------------------------------- | ----------------------------------------- | ------------- | ---------- | -------------------------------------------- |
| `/var/lib/services`                    | Root directory for all service homes      | `root`        | `services` | `2775` setgid → subdirectories inherit group |
| `/var/lib/services/deluge`             | Deluge service state/config               | `deluge`      | `services` | Home dir for system user                     |
| `/var/lib/services/sonarr`             | Sonarr service state/config               | `sonarr`      | `services` | Home dir for system user                     |
| `/var/lib/services/radarr`             | Radarr service state/config               | `radarr`      | `services` | Home dir for system user                     |
| `/var/lib/services/prowlarr`           | Prowlarr state/config                     | `prowlarr`    | `services` | Home dir for system user                     |
| `/var/lib/services/plex`               | Plex config/runtime                       | `plex`        | `services` | Home dir for system user                     |
| `/var/lib/services/tdarr`              | Tdarr runtime/config                      | `tdarr`       | `services` | Home dir for system user                     |
| `/var/lib/services/overseerr`          | Overseerr state/config                    | `overseerr`   | `services` | Home dir for system user                     |
| `/var/lib/services/immich`             | Immich runtime/config                     | `immich`      | `services` | Home dir for system user                     |
| `/var/lib/services/cloudflared`        | Cloudflared tunnel runtime                | `cloudflared` | `services` | Home dir for system user                     |
| `/mnt/vault/immich`                    | Immich photo/video storage                | `immich`      | `immich`   | `2775`, isolated from media                  |
| `/mnt/vault/media`                     | Root media directory (anime/movies/shows) | `root`        | `media`    | `2775` setgid → subdirectories inherit group |
| `/mnt/vault/media/anime`               | Anime library                             | `root`        | `media`    | Media accessible by media services           |
| `/mnt/vault/media/movies`              | Movies library                            | `root`        | `media`    | Media accessible by media services           |
| `/mnt/vault/media/shows`               | TV shows library                          | `root`        | `media`    | Media accessible by media services           |
| `/mnt/vault/downloads`                 | Deluge downloads root                     | `root`        | `media`    | `2775` setgid                                |
| `/mnt/vault/downloads/incomplete`      | In-progress downloads                     | `root`        | `media`    | Subdirectories inherit group                 |
| `/mnt/vault/downloads/complete`        | Completed downloads                       | `root`        | `media`    | Subdirectories inherit group                 |
| `/mnt/vault/downloads/complete/anime`  | Completed anime downloads                 | `root`        | `media`    | Subdirectories inherit group                 |
| `/mnt/vault/downloads/complete/movies` | Completed movies downloads                | `root`        | `media`    | Subdirectories inherit group                 |
| `/mnt/vault/downloads/complete/shows`  | Completed shows downloads                 | `root`        | `media`    | Subdirectories inherit group                 |

---

## 2️⃣ Users and Groups

| User          | Type    | Primary Group | Extra Groups            | Notes                                    |
| ------------- | ------- | ------------- | ----------------------- | ---------------------------------------- |
| `admin`       | Human   | `admin`       | `wheel`, `media`        | SSH / manual management, can rsync files |
| `deluge`      | Service | `media`       | `vpn`, `services`       | Writes to downloads & media              |
| `sonarr`      | Service | `media`       | `vpn`, `services`       | Reads/writes media library               |
| `radarr`      | Service | `media`       | `vpn`, `services`       | Reads/writes media library               |
| `plex`        | Service | `media`       | `transcode`, `services` | Media playback & transcoding             |
| `tdarr`       | Service | `media`       | `transcode`, `services` | Media transcoding                        |
| `prowlarr`    | Service | `services`    | `vpn`                   | Indexing service                         |
| `overseerr`   | Service | `services`    | `media`                 | Needs media access for library requests  |
| `immich`      | Service | `services`    | -                       | Stores photos/videos in separate pool    |
| `cloudflared` | Service | `services`    | -                       | Public tunnel; non-VPN                   |

**Groups Overview:**

| Group       | Purpose                                                                         |
| ----------- | ------------------------------------------------------------------------------- |
| `media`     | Shared access to media libraries and downloads (Radarr/Sonarr/Plex/Tdarr)       |
| `services`  | Organizational / auditing group for service directories (`/var/lib/services`)   |
| `transcode` | Access to GPU / transcoding hardware (Plex & Tdarr)                             |
| `vpn`       | Services that must route traffic through VPN (deluge, sonarr, radarr, prowlarr) |

---

## 3️⃣ Slices / cgroups

| Slice / cgroup | Users / Services                                      | Network Routing                                                       | Notes                                                           |
| -------------- | ----------------------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------------------- |
| `vpn.slice`    | `deluge`, `sonarr`, `radarr`, `prowlarr`              | Force traffic through VPN tunnel interface (e.g., `wg0` or `gluetun`) | All outbound traffic locked to VPN via kernel routing           |
| `normal.slice` | `plex`, `tdarr`, `overseerr`, `immich`, `cloudflared` | Default route                                                         | Unrestricted internet access; Cloudflare tunnel services public |
| `admin.slice`  | `admin`                                               | Default route                                                         | SSH / manual management; can access all directories             |
