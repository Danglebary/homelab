# Home Manager Integration Plan

## Overview
Integrate Home Manager into the existing flakes-based NixOS configuration to support two distinct user environments with proper separation of privileges and Docker isolation. This plan focuses on user environment setup and Docker isolation infrastructure only - specific homelab containers (Plex, Sonarr, etc.) will be configured in a future iteration.

## Current State
- **Existing user**: `halfblown` with admin privileges (wheel group)
- **Configuration**: Modular flakes-based NixOS with working LACP bonding
- **Usage**: Single user environment for system administration

## Target State
- **Admin user**: Full system privileges for homelab service management
- **Dev user**: Sandboxed environment for personal development projects
- **Home Manager**: Declarative user environment management
- **Docker isolation**: Separate Docker environments per user

## User Architecture

### Admin User (`admin`)
**Purpose**: System administration and homelab service management

**Permissions:**
- Full system access (`wheel` group, sudo privileges)
- Docker daemon access (`docker` group)
- Systemd service management
- Network configuration access
- Log file access (`systemd-journal` group)

**Responsibilities:**
- Managing Plex, Sonarr, Radarr, Overseerr, etc.
- System-wide package installation
- NixOS configuration changes
- Docker Compose service management
- Server maintenance and monitoring

**Home Manager Config:**
- System administration tools (htop, docker-compose, etc.)
- Service management aliases and scripts
- Shared git configuration with GitHub SSH key (same GitHub account)
- Shell environment for server administration

### Dev User (`dev`)
**Purpose**: Personal development and hobby projects

**Permissions:**
- Standard user (no sudo access)
- Own home directory management
- Rootless Docker access
- Personal project directories

**Restrictions:**
- Cannot modify system configuration
- Cannot access admin Docker containers
- Cannot install system-wide packages
- Cannot access sensitive system logs

**Responsibilities:**
- Personal development projects
- Learning new technologies
- Hobby programming work
- Personal Docker containers

**Home Manager Config:**
- Development tools (programming languages, editors)
- Shared git configuration with GitHub SSH key (same GitHub account as admin)
- Development aliases and functions
- Rootless Docker setup
- Development shell environment

## Docker Isolation Strategy

### Admin Docker Environment
- **Socket**: `/var/run/docker.sock` (system Docker daemon)
- **Access**: Full privileged access
- **Containers**: Homelab services (Plex, *arr stack, Immich, etc.)
- **Networks**: Production docker networks with VPN routing
- **Storage**: System-managed volumes on ZFS pool

### Dev Docker Environment
- **Implementation**: Rootless Docker
- **Socket**: User-specific socket (`$XDG_RUNTIME_DIR/docker.sock`)
- **Access**: User-isolated, no privileged operations
- **Containers**: Personal development projects only
- **Networks**: User-isolated networks
- **Storage**: ZFS vault pool directories for dev user projects and container data

**Benefits:**
- Complete container isolation
- Dev cannot see/access admin containers
- Separate image storage and caching
- Independent Docker networks

## Security Model

### Access Control
- **Admin user**: Unrestricted system access
- **Dev user**: Restricted to user space and personal Docker
- **SSH access**: Both users can SSH with separate key pairs
- **File permissions**: Standard Unix permissions + Docker isolation

### Home Manager Security
- **Risk mitigation**: Dev user cannot escalate privileges through home-manager
- **User-level only**: Home Manager runs with user permissions
- **System changes**: Require admin user for NixOS rebuilds
- **Configuration**: Dev can only modify own home environment

### SSH Key Management
- **Server access keys (Different)**: Separate SSH keys for accessing each user account on the server
  - Admin user: `ssh -i ~/.ssh/admin_key admin@homelab-hl15`
  - Dev user: `ssh -i ~/.ssh/dev_key dev@homelab-hl15`
- **GitHub access keys (Shared)**: Same SSH key for git operations across both users (single GitHub account)
  - Configured in Home Manager git config, not SSH authorized keys
- **Benefits**: Clear audit trail per user role, separate credential management, shared git workflow

### Remote SSH Access
Both admin and dev users should have remote SSH access capabilities for system administration and development work:

#### Admin User Remote Access
- **Purpose**: Critical system administration when away from home
- **Use Cases**: 
  - Emergency service management and troubleshooting
  - System monitoring and maintenance
  - Docker container management and log review
  - NixOS configuration deployments via git workflow
- **Access Method**: SSH with dedicated admin server key
- **Backup Access**: Essential for homelab reliability

#### Dev User Remote Access  
- **Purpose**: Development work and personal project access
- **Use Cases**:
  - Personal development project management
  - Accessing development environments and tools
  - Managing personal Docker containers and experiments
  - Git operations for personal repositories
- **Access Method**: SSH with dedicated dev server key
- **Restrictions**: Cannot access admin services or perform system changes

#### SSH Configuration Considerations
- **Port Security**: Consider non-standard SSH port for additional security
- **Key-Only Authentication**: Disable password authentication entirely
- **Connection Limits**: Rate limiting and connection monitoring
- **VPN Alternative**: Optional Tailscale/Wireguard for additional security layer
- **Audit Logging**: SSH access logging for security monitoring

## Implementation Structure

```
nixos/
├── flake.nix                    # Updated with Home Manager input
├── configuration.nix            # Main config with user imports
├── hardware-configuration.nix   # Unchanged
├── network.nix                 # Unchanged (working LACP config)
├── localization.nix            # Unchanged
├── display.nix                 # Unchanged
├── audio.nix                   # Unchanged
├── ssh.nix                     # Updated SSH configuration
├── docker.nix                 # NEW: Docker daemon configuration
├── storage.nix                # NEW: ZFS pool mounts and user directories
├── users/
│   ├── admin.nix               # NEW: Admin user system config
│   └── dev.nix                 # NEW: Dev user system config
└── home-manager/
    ├── shared/
    │   └── git.nix             # Shared git configuration (same GitHub account)
    ├── admin/
    │   ├── default.nix         # Admin home config entry point
    │   ├── shell.nix           # Shell config with admin tools
    │   └── packages.nix        # System administration packages
    └── dev/
        ├── default.nix         # Dev home config entry point
        ├── shell.nix           # Development shell environment
        ├── docker.nix          # Rootless Docker setup
        └── packages.nix        # Development tools and languages
```

## Module Breakdown

### New System Modules

#### docker.nix
- Docker daemon configuration
- Admin user Docker group membership
- Rootless Docker enablement for dev user

#### storage.nix
```nix
{
  # ZFS pool user directories (Phase 2: User-specific structure)
  systemd.tmpfiles.rules = [
    # Admin user storage
    "d /mnt/vault/users/admin 0755 admin admin -"
    "d /mnt/vault/users/admin/scripts 0755 admin admin -"
    "d /mnt/vault/users/admin/monitoring 0755 admin admin -"
    "d /mnt/vault/users/admin/maintenance 0755 admin admin -"
    
    # Dev user storage  
    "d /mnt/vault/users/dev 0755 dev dev -"
    "d /mnt/vault/users/dev/projects 0755 dev dev -"
    "d /mnt/vault/users/dev/archive 0755 dev dev -"
    "d /mnt/vault/users/dev/docker-data 0755 dev dev -"
    "d /mnt/vault/users/dev/docker-data/databases 0755 dev dev -"
    "d /mnt/vault/users/dev/docker-data/volumes 0755 dev dev -"
    "d /mnt/vault/users/dev/docker-data/networks 0755 dev dev -"
    "d /mnt/vault/users/dev/tools 0755 dev dev -"
    
    # Centralized logging directory
    "d /var/log/homelab 0755 root root -"
    
    # Telemetry data storage
    "d /mnt/vault/telemetry 0755 root observability -"
    "d /mnt/vault/telemetry/active 0755 root observability -"
    "d /mnt/vault/telemetry/archived 0755 root observability -"
    "d /mnt/vault/telemetry/metrics 0755 prometheus observability -"
    "d /mnt/vault/telemetry/loki 0755 loki observability -"
    "d /mnt/vault/telemetry/grafana 0755 grafana observability -"
    "d /mnt/vault/telemetry/alloy 0755 alloy observability -"
  ];
  
  # Service user groups for security isolation
  users.groups = {
    media = {};
    infrastructure = {}; 
    observability = {};
    web = {};
  };
  
  # Service users (examples - complete during service deployment)
  users.users = {
    # Media services
    plex = { group = "media"; extraGroups = []; isSystemUser = true; };
    sonarr-shows = { group = "media"; extraGroups = []; isSystemUser = true; };
    sonarr-anime = { group = "media"; extraGroups = []; isSystemUser = true; };
    radarr = { group = "media"; extraGroups = []; isSystemUser = true; };
    tdarr = { group = "media"; extraGroups = []; isSystemUser = true; };
    deluge = { group = "media"; extraGroups = []; isSystemUser = true; };
    overseerr = { group = "media"; extraGroups = []; isSystemUser = true; };
    profilarr = { group = "media"; extraGroups = []; isSystemUser = true; };
    
    # Infrastructure services
    pihole = { group = "infrastructure"; extraGroups = []; isSystemUser = true; };
    gluetun = { group = "infrastructure"; extraGroups = []; isSystemUser = true; };
    homepage = { group = "infrastructure"; extraGroups = []; isSystemUser = true; };
    
    # Observability services
    prometheus = { group = "observability"; extraGroups = []; isSystemUser = true; };
    grafana = { group = "observability"; extraGroups = []; isSystemUser = true; };
    uptime-kuma = { group = "observability"; extraGroups = []; isSystemUser = true; };
    alloy = { group = "observability"; extraGroups = []; isSystemUser = true; };
    loki = { group = "observability"; extraGroups = []; isSystemUser = true; };
    
    # Web services
    immich = { group = "web"; extraGroups = []; isSystemUser = true; };
    nextcloud = { group = "web"; extraGroups = []; isSystemUser = true; };
  };
}
```

#### users/admin.nix
```nix
{
  users.users.admin = {
    isNormalUser = true;
    description = "System Administrator";
    extraGroups = [ 
      "wheel" 
      "docker" 
      "systemd-journal"
      "media"           # Access to media files for troubleshooting
      "infrastructure"  # Access to infrastructure services
      "observability"   # Access to monitoring and logs
    ];
    home = "/home/admin";
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAA...admin-server-key user@machine" # Admin server access key
    ];
  };
}
```

#### users/dev.nix
```nix
{
  users.users.dev = {
    isNormalUser = true;
    description = "Development User";
    extraGroups = [ ]; # No special groups
    home = "/home/dev";
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 BBBB...dev-server-key user@machine" # Dev server access key (different)
    ];
  };
}
```

### Home Manager Integration

#### flake.nix Updates
- Add Home Manager as flake input
- Configure Home Manager for both users
- Import home configurations

**Updated flake.nix structure:**
```nix
{
  description = "NixOS configuration for homelab-hl15";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.homelab-hl15 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.admin = import ./home-manager/admin;
          home-manager.users.dev = import ./home-manager/dev;
        }
      ];
    };
  };
}
```

#### Home Manager Configurations
- **Shared**: Git configuration with GitHub SSH key (same GitHub account for both users)
- **Admin**: System tools, service management aliases, docker-compose access
- **Dev**: Development tools, languages, rootless Docker, ZFS project directories

**SSH Key Strategy:**
- **Server access**: Different SSH keys per user account for clear audit trail
- **GitHub access**: Shared SSH key in git config for unified workflow

## Implementation Steps

### Phase 1: Home Manager Integration
1. Update flake.nix with Home Manager input
2. Create basic home-manager directory structure
3. Configure Home Manager for existing `halfblown` user
4. Test Home Manager functionality

### Phase 2: User Creation
1. Create `admin` user system configuration
2. Create `dev` user system configuration  
3. Update SSH configuration for both users
4. Create Docker isolation configuration
5. Update configuration.nix imports to remove `./users/halfblown.nix` and add new user imports

### Phase 3: Home Manager User Configs
1. Create shared git configuration module
2. Create admin home-manager configuration
3. Create dev home-manager configuration
4. Configure shells, tools, and environments
5. Set up rootless Docker for dev user
6. Configure ZFS vault storage directories for dev user

### Phase 4: Migration and Testing
1. Test both user environments
2. Test ZFS vault storage access for dev user
3. Migrate from `halfblown` to `admin` user
4. Remove `halfblown` user from system configuration
5. Remove `./users/halfblown.nix` import from configuration.nix
6. Verify Docker isolation
7. Test SSH access for both users with separate server keys
8. Verify shared GitHub SSH key functionality in git operations

## Migration Strategy

### Safe Migration Process
1. **Backup current state**: Git commit before changes
2. **Keep halfblown**: Maintain during transition for fallback
3. **Test new users**: Verify functionality before removing halfblown
4. **Copy configurations**: Migrate useful configs from halfblown to admin
5. **Clean removal**: Delete halfblown user only after full verification

### Rollback Plan
- Git checkout to revert changes
- Traditional NixOS rebuild if Home Manager issues
- Emergency SSH access via original user during transition

## Benefits

### Security
- Principle of least privilege for dev user
- Complete Docker container isolation
- Separate SSH key management
- Clear audit trail per user

### Organization
- Clean separation of responsibilities
- Declarative user environments
- Reproducible development setup
- Scalable for future users

### Development Workflow
- Personal sandbox environment
- Isolated Docker experimentation
- Personal dotfile management
- Development tool consistency

## Considerations

### Complexity
- Additional configuration to maintain
- More complex user management
- Learning curve for Home Manager

### Resource Usage
- Rootless Docker overhead
- Duplicate package installations per user
- Additional user processes

### Maintenance
- User-specific updates and maintenance
- Home Manager configuration management
- Docker environment maintenance

## Testing Plan

### User Functionality
- SSH access for both users with separate keys (`ssh -i ~/.ssh/admin_key admin@server` vs `ssh -i ~/.ssh/dev_key dev@server`)
- Sudo access (admin only)
- Docker access verification
- Home directory permissions
- Git operations with shared GitHub SSH key

### Docker Isolation
- Admin can manage homelab containers
- Dev cannot see admin containers
- Rootless Docker functionality
- Network isolation verification

### Home Manager
- Configuration application
- Package installation
- Shell environment setup
- Git configuration

## Success Criteria

1. **Complete user separation**: Admin and dev users with appropriate permissions
2. **Docker isolation**: Cannot cross-contaminate between environments
3. **SSH functionality**: Both users can access server remotely
4. **Home Manager working**: Declarative user environment management
5. **Security maintained**: No privilege escalation vulnerabilities
6. **Reproducibility**: Entire user environment in version control

## Notes

- Preserve existing network bonding configuration
- Maintain system stability during migration
- Keep rollback options available at all phases
- Test thoroughly before removing fallback options
- **Scope limitation**: This plan covers user environment setup only, not specific homelab Docker containers
- **Single user context**: Both admin and dev accounts represent the same person with shared git identity
- **Storage strategy**: Dev user gets ZFS storage to prevent boot drive from filling with projects
- **SSH key strategy**: Separate server access keys per user, shared GitHub key for git operations
- **ZFS dependency**: Plan depends on ZFS "vault" pool being configured first - see zfs-setup-plan.md
- **Phase 2 structure**: This plan implements Phase 2 user directory structure on vault pool