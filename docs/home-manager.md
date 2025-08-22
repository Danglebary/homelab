# Home Manager & User Management

## Overview
Comprehensive user and group management strategy for the HL15 homelab server using Home Manager for declarative user environments and NixOS for system-level user accounts. This document defines all human users, service users, domain groups, and access control requirements.

## Human Users

### Admin User (`admin`)
**Purpose**: System administration and homelab service management

**Permissions & Groups:**
- Full system access (`wheel` group, sudo privileges)
- Docker daemon access (`docker` group)
- Systemd service management
- Network configuration access
- Log file access (`systemd-journal` group)
- All domain groups for troubleshooting access

**Responsibilities:**
- Managing all Docker services (Plex, *arr stack, monitoring, etc.)
- System-wide package installation and NixOS configuration changes
- Docker Compose service management and troubleshooting
- Server maintenance and monitoring
- ZFS pool management

**Home Manager Configuration:**
- System administration tools (htop, docker-compose, zfs utilities)
- Service management aliases and scripts
- Shared git configuration with GitHub SSH key
- Shell environment optimized for server administration

**Remote Access Requirements:**
- Critical system administration when away from home via Tailscale mesh network
- Emergency service management and troubleshooting through secure SSH access
- System monitoring and maintenance tasks from any connected device
- NixOS configuration deployments via git workflow over encrypted connection

### Dev User (`dev`)
**Purpose**: Personal development and hobby projects in isolated environment

**Permissions & Groups:**
- Standard user (no sudo access)
- Own home directory management
- Rootless Docker access
- Personal project directories on ZFS vault

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

**Home Manager Configuration:**
- Development tools (programming languages, editors, build tools)
- Shared git configuration with GitHub SSH key (same account as admin)
- Development aliases and functions
- Rootless Docker setup with ZFS storage
- Development shell environment (zsh/fish with dev-focused plugins)

**Remote Access Requirements:**
- Development work and personal project access via Tailscale mesh network
- Accessing development environments and tools through secure SSH connection
- Managing personal Docker containers and experiments remotely
- Git operations for personal repositories over encrypted connection

## Service Users

### Media Services Group
**Domain Group**: `media`
**Storage Access**: `/mnt/vault/media/`, `/mnt/vault/temp/`

#### Core Media Services
- **`plex`**: Media streaming server with hardware transcoding access
- **`tdarr`**: Transcoding automation with GPU access
- **`deluge`**: BitTorrent client (VPN-isolated)
- **`overseerr`**: Media request interface
- **`prowlarr`**: Indexer management for all *arr instances

#### Sonarr Instances  
- **`sonarr.shows`**: TV show management (non-anime content)
  - Storage: `/mnt/vault/media/shows/`
- **`sonarr.anime`**: Anime show management
  - Storage: `/mnt/vault/media/anime/`

#### Radarr Instances
- **`radarr.movies`**: Movie management (non-anime content)
  - Storage: `/mnt/vault/media/movies/`
- **`radarr.anime`**: Anime movie management
  - Storage: `/mnt/vault/media/anime/`

**Anime Content Organization**: Both anime shows and movies are stored in `/mnt/vault/media/anime/` using a flat directory structure to ensure compatibility with Sonarr/Radarr requirements while providing a unified anime section in Plex. Examples:
- `/mnt/vault/media/anime/demon-slayer-kimetsu-no-yaiba/` (TV series)
- `/mnt/vault/media/anime/demon-slayer-mugen-train/` (Movie)
- `/mnt/vault/media/anime/your-name/` (Standalone movie)

#### Quality Management
- **`profilarr`**: Automated custom formats and quality profiles management

### Infrastructure Services Group
**Domain Group**: `infrastructure`
**Storage Access**: `/opt/homelab/services/`, limited ZFS access

- **`pihole`**: DNS and ad blocking
- **`gluetun`**: VPN gateway with kill-switch
- **`homepage`**: Admin dashboard and service links

### Observability Services Group  
**Domain Group**: `observability`
**Storage Access**: `/mnt/vault/telemetry/`, `/var/log/homelab/`

- **`prometheus`**: Time-series metrics collection
- **`grafana`**: Unified observability dashboard  
- **`alloy`**: Unified telemetry collection
- **`loki`**: Centralized log storage and querying

### Immich Service User
**Service User**: `immich`
**Domain Group**: `immich` (independent group)
**Storage Access**: `/mnt/vault/immich/`

- **`immich`**: Photo management and sharing service

### Nextcloud Service User
**Service User**: `nextcloud`
**Domain Group**: `nextcloud` (independent group)
**Storage Access**: `/mnt/vault/nextcloud/`

- **`nextcloud`**: File synchronization and collaboration service

## Domain Groups & Access Control

### Group Membership Matrix

| User/Service | wheel | docker | media | infrastructure | observability | immich | nextcloud |
|--------------|-------|--------|-------|----------------|---------------|--------|-----------|
| `admin` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `dev` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Media services | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Infrastructure services | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| Observability services | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ |
| Immich service | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ |
| Nextcloud service | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |

### Storage Access Permissions

| Path | admin | dev | media | infrastructure | observability | immich | nextcloud |
|------|-------|-----|-------|----------------|---------------|--------|-----------|
| `/opt/homelab/services/` | RW | R | R | RW | R | R | R |
| `/mnt/vault/media/` | RW | R | RW | R | R | R | R |
| `/mnt/vault/temp/` | RW | R | RW | R | R | R | R |
| `/mnt/vault/users/admin/` | RW | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| `/mnt/vault/users/dev/` | RW | RW | ✗ | ✗ | ✗ | ✗ | ✗ |
| `/mnt/vault/telemetry/` | RW | R | R | R | RW | R | R |
| `/mnt/vault/immich/` | RW | R | ✗ | ✗ | ✗ | RW | ✗ |
| `/mnt/vault/nextcloud/` | RW | R | ✗ | ✗ | ✗ | ✗ | RW |
| `/var/log/homelab/` | RW | R | R | R | RW | R | R |

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
- **Storage**: ZFS vault pool directories for dev projects and container data

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

- [ ] Complete user separation between admin and dev
- [ ] Docker isolation prevents environment cross-contamination  
- [ ] SSH functionality working for both users
- [ ] Home Manager managing declarative user environments
- [ ] Service users properly isolated by domain groups
- [ ] Remote access implemented and secure
- [ ] Clear audit trail for all user actions
- [ ] No privilege escalation vulnerabilities
- [ ] All user environments reproducible through version control

## Notes

- Both admin and dev users represent the same person with different roles
- Service user accounts provide security isolation between Docker services
- Storage strategy uses ZFS for dev projects to prevent boot drive overflow
- Domain groups enable fine-grained access control without user proliferation
- Home Manager ensures consistent, reproducible user environments
- Remote access strategy balances security with usability requirements