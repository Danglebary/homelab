# ZFS Storage Setup Plan

## Overview
Configure ZFS storage pool for HL15 homelab server using mirror topology for optimal performance and redundancy. Initial setup with 2x 20TB drives, designed for future expansion to full 15-bay capacity.

## Current Storage State
- **Hardware**: HL15 chassis with 15 hot-swap bays
- **Current drives**: 2x Western Digital Ultrastar HC560 20TB SAS drives (unused, from serverpartdeals.com)
- **Status**: Drives visible in `lsblk` but unpartitioned/unused
- **Future expansion**: Purchase additional drives in pairs over time

## ZFS Design Philosophy

### Topology Choice: Mirror vdevs
**Decision**: Multiple 2-drive mirror vdevs in a single pool
**Reasoning**: 
- **Homelab-optimal**: Perfect balance of performance, redundancy, and expansion flexibility
- **Media workload**: Excellent for Plex streaming (high read performance)
- **Dev workload**: Good random I/O for development projects and databases
- **Expansion**: Simple addition of new mirror vdevs as drive pairs are purchased

### Capacity Planning
- **Current**: 2 drives = 1 mirror vdev = 20TB usable
- **Full build**: 14 drives = 7 mirror vdevs = 140TB usable (1 spare drive)
- **Future capacity**: ~9,300 4K H.265 movies (avg 15GB each)

## Pool Topology Design

### Initial Pool (2 drives)
```
pool: vault
 state: ONLINE
 config:
    NAME        STATE
    vault       ONLINE
      mirror-0  ONLINE
        sda     ONLINE
        sdb     ONLINE
```

### Future Full Pool (15 drives)
```
pool: vault
 state: ONLINE
 config:
    NAME        STATE
    vault       ONLINE
      mirror-0  ONLINE  # Initial pair
        sda     ONLINE
        sdb     ONLINE
      mirror-1  ONLINE  # Expansion pair 1
        sdc     ONLINE
        sdd     ONLINE
      mirror-2  ONLINE  # Expansion pair 2
        sde     ONLINE
        sdf     ONLINE
      # ... up to mirror-6 (7 total vdevs)
    spare
      sdx       AVAIL   # 15th drive as hot spare
```

## Dataset Structure

### Phase 1: Initial Dataset Hierarchy (ZFS Setup)
```
vault/                          # Root dataset
├── system/                     # System-related data
├── users/                      # User home directories and projects  
├── media/                      # Media library storage
└── temp/                       # Temporary storage
```

**Phase 1 Focus:** Create major categories only. Detailed subdirectories will be added in later phases as services are implemented.

## Dataset Properties and Optimization

### Performance Optimizations (Phase 1)
```nix
# Media storage (large sequential files)
vault/media {
  recordsize = "1M"          # Large blocks for video files
  compression = "gzip-1"     # Better compression for media
  atime = "off"              # No access time tracking
}

# User data (mixed development workload)
vault/users {
  recordsize = "128K"        # Good for mixed file sizes
  compression = "lz4"        # Fast compression
  atime = "off"              # No access time updates
}

# System data (will be refined in later phases)
vault/system {
  recordsize = "128K"        # Default for now, will optimize per service later
  compression = "lz4"        # Fast compression
  atime = "off"              # No access time updates
}

# Temporary/download areas
vault/temp {
  recordsize = "128K"        # Mixed workload
  compression = "lz4"        # Fast compression
  sync = "disabled"          # Performance over safety for temp data
}
```

### Mount Points (Phase 1)
```
/vault                      # Pool root (not typically used directly)
/mnt/vault/system          # System data
/mnt/vault/users           # User directories
/mnt/vault/media           # Media libraries
/mnt/vault/temp            # Temporary storage
```

## ZFS Performance Settings

### Pool-Level Optimizations
```bash
# ARC (cache) settings for 256GB RAM system
echo 128G > /sys/module/zfs/parameters/zfs_arc_max    # Limit ARC to 128GB
echo 64G > /sys/module/zfs/parameters/zfs_arc_min     # Minimum ARC 64GB

# Record size optimization (Phase 1)
zfs set recordsize=1M vault/media         # Large files (video)
zfs set recordsize=128K vault/users       # Mixed workload
zfs set recordsize=128K vault/system      # Default for now, optimize later
zfs set recordsize=128K vault/temp        # Mixed temporary workload
```

### SAS Drive Optimizations
```bash
# Enable write cache (safe with UPS or enterprise drives)
echo write-back > /sys/block/sd*/queue/scheduler

# Optimize for SAS drives
echo mq-deadline > /sys/block/sd*/queue/scheduler
```

## Snapshot Strategy

### Automated Snapshots (Phase 1)
```bash
# User data snapshots
vault/users                 # Hourly, keep 24 hours
                            # Daily, keep 7 days
                            # Weekly, keep 4 weeks

# Media snapshots (changes less frequently)
vault/media                 # Daily, keep 7 days
                            # Weekly, keep 4 weeks
                            # Monthly, keep 6 months

# System data snapshots
vault/system                # Hourly, keep 24 hours
                            # Daily, keep 30 days
                            # Weekly, keep 12 weeks

# Temporary data (minimal snapshots)
vault/temp                  # Daily, keep 3 days
```

### Snapshot Naming Convention
```
vault/users@auto-2025-01-21-15:00
vault/media@daily-2025-01-21
vault/system@weekly-2025-01-20
```

## Implementation Plan

### Phase 1: Pool Creation and Basic Setup
1. **Verify drive status** and wipe existing data
2. **Create initial pool** with 2-drive mirror
3. **Set basic pool properties** (compression, atime, etc.)
4. **Create initial dataset structure**
5. **Configure mount points** and permissions
6. **Test basic functionality**

### Phase 2: Basic Dataset Configuration
1. **Create Phase 1 datasets** (system, users, media, temp)
2. **Set up mount points** and basic directory structure
3. **Configure basic permissions** 
4. **Set initial recordsize optimization**
5. **Test basic functionality**

### Phase 3: Integration and Automation
1. **Configure automatic snapshots** with sanoid/syncoid
2. **Set up monitoring** (ZFS health, capacity, performance)
3. **Create maintenance scripts** (scrub scheduling, etc.)
4. **Document operational procedures**
5. **Test disaster recovery procedures**

### Phase 4: Future Expansion Preparation
1. **Document expansion procedures** for adding vdevs
2. **Test expansion process** with virtual machines
3. **Plan capacity monitoring** and alerts
4. **Prepare for drive replacement procedures**

## Safety and Recovery Procedures

### Pre-Implementation Safety
- **Full system backup** of current boot drive configuration
- **Git commit** all current configurations
- **Document rollback procedures**
- **Prepare recovery boot media**

### Drive Replacement Procedures
```bash
# When a drive fails in a mirror
zpool offline tank /dev/old-drive    # Take offline
# Physical drive replacement
zpool replace tank /dev/old-drive /dev/new-drive
zpool online tank /dev/new-drive     # Bring online
# ZFS will automatically resilver
```

### Regular Maintenance
```bash
# Monthly scrub (verify data integrity)
zpool scrub tank

# Check pool health
zpool status tank

# Monitor capacity
zfs list -o space tank

# Check for errors
zpool status -v tank
```

## NixOS Integration

### ZFS Module Configuration
```nix
# Enable ZFS support
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.extraPools = [ "vault" ];

# ZFS services
services.zfs = {
  autoScrub = {
    enable = true;
    interval = "monthly";
    pools = [ "vault" ];
  };
  autoSnapshot = {
    enable = true;
    frequent = 8;    # 15-minute snapshots, keep 8 (2 hours)
    hourly = 24;     # Hourly snapshots, keep 24
    daily = 7;       # Daily snapshots, keep 7
    weekly = 4;      # Weekly snapshots, keep 4
    monthly = 6;     # Monthly snapshots, keep 6
  };
};

# Mount datasets
fileSystems."/mnt/vault" = {
  device = "vault";
  fsType = "zfs";
  options = [ "zfsutil" ];
};
```

### Dataset Mount Configuration (Phase 1)
```nix
# Basic directory structure - detailed subdirectories added in later phases
systemd.tmpfiles.rules = [
  # Main datasets
  "d /mnt/vault/system 0755 root root -"
  "d /mnt/vault/users 0755 root root -"
  "d /mnt/vault/media 0755 root root -"
  "d /mnt/vault/temp 0755 root root -"
];
```

## Drive Identification and Preparation

### Initial Drive Discovery
```bash
# List all block devices with model info
lsblk -o KNAME,TYPE,SIZE,MODEL

# Identify the 20TB drives specifically
lsblk -o KNAME,TYPE,SIZE,MODEL | grep "WUH722020"

# Check for existing partitions/filesystems
sudo blkid

# Wipe drives completely (DESTRUCTIVE - BE CAREFUL)
sudo wipefs -a /dev/sdX  # Replace X with actual drive letters
sudo sgdisk --zap-all /dev/sdX
```

### Pool Creation Commands
```bash
# Create the initial mirror pool
sudo zpool create -f vault mirror /dev/disk/by-id/scsi-DRIVE1-ID /dev/disk/by-id/scsi-DRIVE2-ID

# Set pool properties
sudo zfs set compression=lz4 vault
sudo zfs set atime=off vault
sudo zfs set relatime=on vault

# Create Phase 1 datasets with optimized properties
sudo zfs create -o recordsize=1M vault/media
sudo zfs create -o recordsize=128K vault/users  
sudo zfs create -o recordsize=128K vault/system
sudo zfs create -o recordsize=128K vault/temp
```

## Future Expansion Process

### Adding New Mirror vdevs
```bash
# When adding drives 3 & 4
sudo zpool add vault mirror /dev/disk/by-id/scsi-DRIVE3-ID /dev/disk/by-id/scsi-DRIVE4-ID

# When adding drives 5 & 6
sudo zpool add vault mirror /dev/disk/by-id/scsi-DRIVE5-ID /dev/disk/by-id/scsi-DRIVE6-ID

# Continue pattern for each pair
```

### Hot Spare Configuration (15th drive)
```bash
# Add the 15th drive as a hot spare
sudo zpool add vault spare /dev/disk/by-id/scsi-SPARE-DRIVE-ID

# ZFS will automatically use the spare if any mirror drive fails
```

## Monitoring and Alerts

### Health Monitoring
```bash
# Daily health check script
#!/bin/bash
POOL_STATUS=$(zpool status vault | grep state: | awk '{print $2}')
if [ "$POOL_STATUS" != "ONLINE" ]; then
    echo "WARNING: ZFS pool 'vault' status is $POOL_STATUS" | mail -s "ZFS Alert" admin@localhost
fi

# Capacity monitoring
USAGE=$(zfs list -H -o used,avail vault | awk '{print ($1/($1+$2))*100}')
if (( $(echo "$USAGE > 80" | bc -l) )); then
    echo "WARNING: ZFS pool 'vault' is ${USAGE}% full" | mail -s "ZFS Capacity Alert" admin@localhost
fi
```

### Performance Monitoring
```bash
# Monitor I/O statistics
zpool iostat vault 1

# Monitor ARC effectiveness
arcstat

# Check fragmentation
zpool list -o fragmentation vault
```

## Disaster Recovery

### Pool Import/Export
```bash
# Export pool (for maintenance or moving)
sudo zpool export vault

# Import pool (after maintenance or system rebuild)
sudo zpool import vault

# Import with different name (for recovery)
sudo zpool import vault vault-recovery
```

### Data Recovery Scenarios
1. **Single drive failure**: ZFS automatically maintains availability, replace drive
2. **Multiple drive failure**: If more than 1 drive per vdev fails, restore from snapshots
3. **Pool corruption**: Import read-only, copy data to new pool
4. **Complete system failure**: Import pool on new NixOS system

## Testing Plan

### Initial Setup Testing
1. **Pool creation** and basic functionality
2. **Dataset creation** and mount point verification
3. **Permission testing** for admin/dev users
4. **Performance baseline** testing with various workloads
5. **Snapshot creation** and rollback testing

### Failure Testing (in VM environment)
1. **Simulate drive failure** and replacement
2. **Test snapshot rollback** procedures
3. **Test pool import/export** functionality
4. **Verify data integrity** after various failure scenarios

### Performance Testing
1. **Sequential read/write** performance (Plex streaming simulation)
2. **Random I/O** performance (development workload simulation)
3. **Mixed workload** testing (multiple concurrent operations)
4. **Compression effectiveness** testing with different data types

## Success Criteria

1. **Pool creation successful** with 2-drive mirror
2. **All datasets created** with appropriate properties
3. **Mount points working** with correct permissions
4. **Snapshots functioning** automatically
5. **Performance acceptable** for intended workloads
6. **Monitoring active** with health checks
7. **Expansion procedures documented** and tested
8. **Integration with NixOS** complete and stable

## Dependencies and Prerequisites

### NixOS Configuration
- ZFS kernel modules loaded
- Appropriate udev rules for drive identification
- User accounts (admin/dev) created
- Permissions and groups configured

### Hardware Requirements
- 2x 20TB SAS drives installed and detected
- Adequate RAM for ZFS ARC (64GB+ allocated)
- Reliable power (UPS recommended for write safety)

### Software Tools
- ZFS utilities (zpool, zfs commands)
- Monitoring tools (arcstat, iostat)
- Snapshot management (sanoid/syncoid)
- Health checking scripts

## Notes

- **Drive identification**: Use `/dev/disk/by-id/` paths for stability
- **Expansion timing**: Add drives in pairs to maintain mirror topology
- **Performance**: Mirror topology provides excellent read performance for media streaming
- **Redundancy**: Can lose up to 1 drive per vdev (up to 7 total in full build)
- **Capacity efficiency**: 50% due to mirroring, but excellent for data safety
- **Future compatibility**: Easy to expand by adding new mirror vdevs
- **Phased approach**: Start with basic structure, expand as services are added
- **Pool naming**: "vault" reflects the secure storage nature of the homelab