# Home Manager & User Management

## Overview
Comprehensive user and group management strategy for the HL15 homelab server using Home Manager for declarative user environments and NixOS for system-level user accounts. This document defines all human users, service users, domain groups, and access control requirements.

## Human Users

### Admin User (`admin`)
**Purpose**: System administration and homelab service management
**Home Directory**: `/home/admin` (on NVMe drive for performance)
**UID**: 1001

**Groups**: `wheel`, `docker`, `services`, `anime`, `shows`, `movies`, `downloads`, `transcoding`, `cleanup`, `systemd-journal`

**Permissions & Access:**
- Full system access (sudo privileges via `wheel` group)
- Docker daemon access for service management
- Complete access to all media directories via content groups
- Access to processing directories for troubleshooting
- System log access and cleanup permissions

**Responsibilities:**
- Managing all Docker services (Plex, *arr stack, monitoring, etc.)
- System-wide package installation and NixOS configuration changes
- Docker Compose service management and troubleshooting
- Server maintenance and monitoring
- ZFS pool management

**Admin Tools & Packages:**
- System administration tools (htop, docker, zfs utilities, git, just)
- Command-line utilities (tree, curl, wget, vim)
- Docker CLI with compose functionality
- Shell environment optimized for server administration

**Remote Access Requirements:**
- Critical system administration when away from home via Tailscale mesh network
- Emergency service management and troubleshooting through secure SSH access
- System monitoring and maintenance tasks from any connected device
- NixOS configuration deployments via git workflow over encrypted connection

### Dev User (`dev`)
**Purpose**: Personal development and hobby projects in isolated environment
**Home Directory**: `/home/dev` (on NVMe drive for performance)
**UID**: 1002

**Groups**: None (complete isolation from system services)

**Permissions & Access:**
- Standard user (no sudo access)  
- Rootless Docker access for isolated containers
- Own home directory management only

**Restrictions:**
- Cannot modify system configuration
- Cannot access admin Docker containers
- Cannot install system-wide packages
- Cannot access sensitive system logs or admin services

**Responsibilities:**
- Personal development projects
- Learning new technologies and experimentation
- Hobby programming work
- Personal Docker containers (isolated from admin services)

**Development Stack & Packages:**
- **Languages**: Go, Bun (JavaScript/TypeScript), Elixir, Rust, Zig
- **Editor**: Neovim  
- **Tools**: git, curl, jq, tree, htop, just, wget, ripgrep, fd
- **Container Platform**: Rootless Docker (isolated from system services)
- **Shell**: Bash

**Remote Access Requirements:**
- Development work and personal project access via Tailscale mesh network
- Accessing development environments and tools through secure SSH connection
- Managing personal rootless Docker containers remotely
- Git operations for personal repositories over encrypted connection

## Service Users

### NixOS Module Structure
Service users are managed through modular NixOS configuration files organized by service and domain group:

```
nixos/modules/
├── services/
│   ├── plex/user.nix           # Plex media server user
│   ├── tdarr/user.nix          # Transcoding service user
│   ├── deluge/user.nix         # BitTorrent client user
│   ├── overseerr/user.nix      # Media request interface user
│   ├── prowlarr/user.nix       # Indexer management user
│   ├── sonarr/
│   │   ├── shows/user.nix      # TV shows management user
│   │   └── anime/user.nix      # Anime shows management user
│   ├── radarr/
│   │   ├── movies/user.nix     # Movies management user
│   │   └── anime/user.nix      # Anime movies management user
│   ├── profilarr/user.nix      # Quality profile management user
│   ├── pihole/user.nix         # DNS and ad blocking user
│   ├── gluetun/user.nix        # VPN gateway user
│   ├── homepage/user.nix       # Dashboard service user
│   ├── prometheus/user.nix     # Metrics collection user
│   ├── grafana/user.nix        # Dashboards service user
│   ├── alloy/user.nix          # Telemetry collection user
│   ├── loki/user.nix           # Log aggregation user
│   ├── immich/user.nix         # Photo management user
│   └── nextcloud/user.nix      # File sync service user
├── groups/
│   ├── media/media.nix         # Media domain group definition
│   ├── infrastructure/infrastructure.nix  # Infrastructure domain group
│   ├── observability/observability.nix    # Monitoring domain group
│   ├── immich/immich.nix       # Immich standalone group
│   └── nextcloud/nextcloud.nix # Nextcloud standalone group
└── default.nix                 # Imports all service and group modules
```

### Media Services Content-Based Groups
**Group Architecture**: Content-based groups for better access control and pipeline safety

**Base Service Group:**
- `services` (GID 3000): Base group for all service users

**Content Type Groups:**
- `anime` (GID 3010): Controls `/mnt/vault/media/anime/`
- `shows` (GID 3011): Controls `/mnt/vault/media/shows/`  
- `movies` (GID 3012): Controls `/mnt/vault/media/movies/`

**Processing Stage Groups:**
- `downloads` (GID 3020): Controls `/mnt/vault/temp/downloads/`
- `transcoding` (GID 3021): Controls `/mnt/vault/transcoded/`
- `cleanup` (GID 3025): Can delete old files from processing directories

#### Core Media Services
- **`plex`**: Media streaming server with hardware transcoding access
  - Groups: `[anime, shows, movies]` (direct media access)
- **`tdarr`**: Transcoding automation with GPU access
  - Groups: `[transcoding]`
- **`deluge`**: BitTorrent client (VPN-isolated)
  - Groups: `[downloads]`
- **`overseerr`**: Media request interface
  - Groups: `[services]` (API-based, no direct media access)
- **`prowlarr`**: Indexer management for all *arr instances
  - Groups: `[services]` (API-based, no direct media access)

#### Sonarr Instances  
- **`sonarr.shows`**: TV show management (non-anime content)
  - Storage: `/mnt/vault/media/shows/`
  - Groups: `[shows]`
  - NixOS Module: `nixos/modules/users/services/sonarr/shows/user.nix`
- **`sonarr.anime`**: Anime show management
  - Storage: `/mnt/vault/media/anime/`
  - Groups: `[anime]`
  - NixOS Module: `nixos/modules/users/services/sonarr/anime/user.nix`

#### Radarr Instances
- **`radarr.movies`**: Movie management (non-anime content)
  - Storage: `/mnt/vault/media/movies/`
  - Groups: `[movies]`
  - NixOS Module: `nixos/modules/users/services/radarr/movies/user.nix`
- **`radarr.anime`**: Anime movie management
  - Storage: `/mnt/vault/media/anime/`
  - Groups: `[anime]`
  - NixOS Module: `nixos/modules/users/services/radarr/anime/user.nix`

**Anime Content Organization**: Both anime shows and movies are stored in `/mnt/vault/media/anime/` using a flat directory structure to ensure compatibility with Sonarr/Radarr requirements while providing a unified anime section in Plex. Examples:
- `/mnt/vault/media/anime/demon-slayer-kimetsu-no-yaiba/` (TV series)
- `/mnt/vault/media/anime/demon-slayer-mugen-train/` (Movie)
- `/mnt/vault/media/anime/your-name/` (Standalone movie)

#### Quality Management
- **`profilarr`**: Automated custom formats and quality profiles management
  - Groups: `[services]` (API-based, no direct media access)

### NixOS Configuration Integration
Each service user module handles:
- User account creation with appropriate UID/GID ranges
- Home directory setup with correct permissions
- Group membership assignment
- Directory creation for service data
- File permission management for Docker volume mounts
- Uses setgid permissions (2775) for shared directories to ensure proper group inheritance

Example service user module structure:
```nix
# nixos/modules/users/services/plex/user.nix
{ config, lib, pkgs, ... }:
{
  users.users.plex = {
    isSystemUser = true;
    group = "services";
    extraGroups = [ "media-server", "anime", "shows", "movies" ];
    uid = 2001;  # Consistent UID for Docker containers
    home = "/var/lib/services/plex";
    createHome = true;
  };
  
  # Ensure required directories exist with correct permissions
  systemd.tmpfiles.rules = [
    # Service runtime directory (service manages internal structure)
    "d /var/lib/services/plex 0755 plex services -"
  ];
}
```

### Infrastructure Services
**Base Group**: All use `services` group
**Storage Access**: `/var/lib/services/[service]/`, limited ZFS access as needed

- **`gluetun`**: VPN gateway with kill-switch
- **`pihole`**: DNS and ad blocking
- **`homepage`**: Admin dashboard and service links

### Observability Services
**Base Group**: All use `services` group  
**Storage Access**: `/var/lib/services/[service]/`, `/mnt/vault/telemetry/`, `/var/log/homelab/`

- **`alloy`**: Unified telemetry collection
- **`loki`**: Centralized log storage and querying
- **`prometheus`**: Time-series metrics collection
- **`grafana`**: Unified observability dashboard

### Self-Hosting Services
**Base Group**: All use `services` group
**Storage Access**: `/var/lib/services/[service]/`, `/mnt/vault/[service]/`

- **`immich`**: Photo management and sharing service
- **`nextcloud`**: File synchronization and collaboration service

## Domain Groups & Access Control

### Group Membership Matrix

| User/Service | wheel | docker | services | anime | shows | movies | downloads | transcoding | cleanup |
|--------------|-------|--------|----------|-------|-------|--------|-----------|-------------|---------|
| `admin` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `dev` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Media content services | ✗ | ✗ | ✓ | ✓* | ✓* | ✓* | ✗ | ✗ | ✗ |
| Processing services | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓* | ✓* | ✗ |
| Other services | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

*Only specific services join content/processing groups as needed

### Storage Access Permissions

| Path | admin | dev | services | anime | shows | movies | downloads | transcoding |
|------|-------|-----|----------|-------|-------|--------|-----------|-------------|
| `/opt/homelab/services/` | RW | R | R | R | R | R | R | R |
| `/var/lib/services/` | RW | ✗ | RW | R | R | R | R | R |
| `/mnt/vault/media/anime/` | RW | R | R | RW | R | R | R | R |
| `/mnt/vault/media/shows/` | RW | R | R | R | RW | R | R | R |
| `/mnt/vault/media/movies/` | RW | R | R | R | R | RW | R | R |
| `/mnt/vault/temp/downloads/` | RW | R | R | R | R | R | RW | R |
| `/mnt/vault/transcoded/` | RW | R | R | R | R | R | R | RW |
| `/mnt/vault/users/dev/` | RW | RW | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| `/mnt/vault/telemetry/` | RW | R | RW | R | R | R | R | R |
| `/mnt/vault/immich/` | RW | R | RW* | R | R | R | R | R |
| `/mnt/vault/nextcloud/` | RW | R | RW* | R | R | R | R | R |

*Only immich/nextcloud services get RW access to their specific directories

## Docker Isolation Strategy

### Admin Docker Environment
- **Socket**: `/var/run/docker.sock` (system Docker daemon)
- **Access**: Full privileged access for homelab services
- **Containers**: All production homelab services
- **Networks**: Production networks with VPN routing (Gluetun)
- **Storage**: System-managed volumes on ZFS pool

### Dev Docker Environment  
- **Implementation**: Rootless Docker for complete isolation
- **Socket**: User-specific socket (`$XDG_RUNTIME_DIR/docker.sock`)
- **Access**: User-isolated, no privileged operations
- **Containers**: Personal development projects only
- **Networks**: User-isolated networks (cannot access admin containers)
- **Storage**: Container data in dev user's isolated namespace

## SSH Key Management Strategy

### Server Access Keys (Separate)
Different SSH keys for accessing each user account on the server:
- **Admin access**: `ssh -i ~/.ssh/admin_server_key admin@homelab-hl15`
- **Dev access**: `ssh -i ~/.ssh/dev_server_key dev@homelab-hl15`

**Benefits**: Clear audit trail per user role, separate credential management

### GitHub Access Keys (Shared)  
Same SSH key for git operations across both users:
- Configured in Home Manager git config, not SSH authorized_keys
- Single GitHub account workflow for both admin and dev users
- Simplifies repository access and commit attribution

## Remote Access Strategy

### Implementation: Tailscale Mesh VPN

**Decision**: Use Tailscale for secure remote access to both admin and dev user accounts.

**Rationale:**
- Zero port forwarding required (no router configuration)
- Modern zero-trust networking approach
- Excellent developer experience and reliability
- Works across all network configurations (NAT, firewalls, etc.)
- Provides secure access to entire homelab network, not just SSH
- Tailscale free tier (20 devices, 1 user) exceeds project requirements
- Future-proof for additional services and devices

**Implementation Details:**
- Install Tailscale on HL15 server at system level
- Connect development machines to Tailscale network
- SSH directly to server's Tailscale IP addresses:
  - Admin access: `ssh admin@100.x.x.x` 
  - Dev access: `ssh dev@100.x.x.x`
- Separate SSH keys maintained for each user account
- No changes required to existing SSH configuration

**Security Benefits:**
- Encrypted mesh networking with automatic key rotation
- Device identity verification through Tailscale
- No exposed ports on public internet
- Access logs and device management through Tailscale admin console
- Can be combined with existing SSH key-based authentication

**Network Access Scope:**
- SSH access to both admin and dev users
- Direct access to internal services (monitoring, admin dashboards)
- Secure file transfer and development workflows
- Future expansion to additional homelab services


## Security Considerations

### Principle of Least Privilege
- Dev user restricted to personal workspace
- Service users limited to required resources only
- Admin user has full access but clear audit trail

### Container Security
- Complete Docker isolation between admin and dev environments
- Service users run containers with minimal privileges
- Network isolation prevents cross-service access

### Access Control
- SSH key-based authentication only
- Regular key rotation procedures
- Separate keys for different access patterns

### Audit and Monitoring
- User action logging through journald
- SSH access monitoring and alerting
- Container activity tracking

## Future Considerations

### Scaling Users
- Framework supports additional human users
- Service user pattern scales with new services
- Group-based permissions simplify access management

### Service Expansion
- New services fit into existing domain groups
- User creation automated through NixOS configuration
- Home Manager handles user environment consistency

### Multi-Machine Setup
- User configurations portable across machines
- Centralized authentication possible
- Home Manager enables consistent environments

## Success Criteria

### Human Users
- [ ] Complete user separation between admin and dev
- [ ] Docker isolation prevents environment cross-contamination  
- [ ] SSH functionality working for both users
- [ ] Home Manager managing declarative user environments
- [ ] Remote access implemented and secure
- [ ] Clear audit trail for all user actions
- [ ] No privilege escalation vulnerabilities
- [ ] All user environments reproducible through version control

### Service Users & NixOS Integration
- [ ] All service users defined in modular NixOS configuration files
- [ ] Domain groups properly configured with correct membership
- [ ] Service directories created with appropriate permissions
- [ ] Docker containers can access required directories with correct ownership
- [ ] UID/GID consistency between NixOS users and Docker containers
- [ ] Directory permissions survive system rebuilds and updates
- [ ] Service user modules are reusable and maintainable

## Notes

- Both admin and dev users represent the same person with different roles
- Service user accounts provide security isolation between Docker services
- Storage strategy uses ZFS for dev projects to prevent boot drive overflow
- Domain groups enable fine-grained access control without user proliferation
- Home Manager ensures consistent, reproducible user environments
- Remote access strategy balances security with usability requirements