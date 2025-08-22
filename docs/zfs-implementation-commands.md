# ZFS Implementation Commands

## Pre-Implementation Safety Checklist

### 1. System Backup
- [ ] Current NixOS configuration backed up in git
- [ ] Boot drive configuration saved
- [ ] Network configuration tested and working
- [ ] Emergency access plan in place

### 2. Drive Verification
- [ ] Verify 20TB drives are detected: `lsblk -o KNAME,TYPE,SIZE,MODEL`
- [ ] Confirm drives are unused: `sudo blkid`
- [ ] Identify exact drive paths: `ls -la /dev/disk/by-id/`

## Implementation Commands

### Step 1: Drive Discovery and Preparation
```bash
# List all drives to identify 20TB drives
lsblk -o KNAME,TYPE,SIZE,MODEL

# Look for WUH722020 model drives
lsblk -o KNAME,TYPE,SIZE,MODEL | grep "WUH722020"

# Get stable device IDs (use these in pool creation)
ls -la /dev/disk/by-id/ | grep -i WUH722020

# Check for existing partitions (should be empty)
sudo blkid

# DESTRUCTIVE: Wipe drives completely (ONLY if confirmed unused)
# Replace DRIVE1-ID and DRIVE2-ID with actual disk IDs from above
sudo wipefs -a /dev/disk/by-id/DRIVE1-ID
sudo wipefs -a /dev/disk/by-id/DRIVE2-ID
sudo sgdisk --zap-all /dev/disk/by-id/DRIVE1-ID
sudo sgdisk --zap-all /dev/disk/by-id/DRIVE2-ID
```

### Step 2: Pool Creation
```bash
# Create vault pool with mirror topology
# CRITICAL: Replace DRIVE1-ID and DRIVE2-ID with actual IDs from Step 1
sudo zpool create -f vault mirror /dev/disk/by-id/DRIVE1-ID /dev/disk/by-id/DRIVE2-ID

# Verify pool creation
zpool status vault
zpool list vault
```

### Step 3: Pool Configuration
```bash
# Set pool-level properties
sudo zfs set compression=lz4 vault
sudo zfs set atime=off vault
sudo zfs set relatime=on vault
```

### Step 4: Dataset Creation
```bash
# Create Phase 1 datasets with optimized properties
sudo zfs create -o recordsize=1M -o compression=gzip-1 vault/media
sudo zfs create -o recordsize=128K -o compression=lz4 vault/users
sudo zfs create -o recordsize=128K -o compression=lz4 vault/system
sudo zfs create -o recordsize=128K -o compression=lz4 -o sync=disabled vault/temp
```

### Step 5: Verify Dataset Configuration
```bash
# Check all datasets and their properties
zfs list -o name,used,avail,refer,mountpoint,recordsize,compression vault
zfs get all vault | grep -E "(recordsize|compression|atime)"
```

### Step 6: Copy New Configuration to Server
```bash
# Copy the entire nixos directory to the server
# (Replace with your server IP/hostname)
scp -r /path/to/nixos/ user@homelab-hl15:/tmp/nixos-new

# On server: backup current config
sudo cp -r /etc/nixos /etc/nixos.backup.$(date +%Y%m%d)

# On server: replace configuration
sudo cp -r /tmp/nixos-new/* /etc/nixos/
```

### Step 7: NixOS Configuration Update
```bash
# On server: Test configuration
sudo nixos-rebuild dry-build

# If dry-build succeeds, apply configuration
sudo nixos-rebuild switch

# Verify ZFS module loaded
lsmod | grep zfs

# Check vault pool auto-import
zpool status vault
```

### Step 8: Verify Mount Points
```bash
# Check that datasets are mounted
mount | grep vault
zfs mount

# Verify directory structure created
ls -la /mnt/vault/
ls -la /mnt/vault/system/
ls -la /mnt/vault/users/
ls -la /mnt/vault/media/
ls -la /mnt/vault/temp/
```

## Post-Implementation Verification

### Basic Functionality Tests
```bash
# Test write/read to each dataset
echo "test" | sudo tee /mnt/vault/system/test.txt
echo "test" | sudo tee /mnt/vault/users/test.txt
echo "test" | sudo tee /mnt/vault/media/test.txt
echo "test" | sudo tee /mnt/vault/temp/test.txt

# Verify files exist
ls -la /mnt/vault/*/test.txt

# Clean up test files
sudo rm /mnt/vault/*/test.txt
```

### Snapshot Testing
```bash
# Create manual snapshot
sudo zfs snapshot vault/system@test-snapshot

# List snapshots
zfs list -t snapshot

# Delete test snapshot
sudo zfs destroy vault/system@test-snapshot
```

### Performance Testing
```bash
# Test sequential write performance
dd if=/dev/zero of=/mnt/vault/temp/test-large bs=1M count=1000

# Test read performance
dd if=/mnt/vault/temp/test-large of=/dev/null bs=1M

# Clean up
rm /mnt/vault/temp/test-large
```

### Health Monitoring
```bash
# Pool health
zpool status vault

# Pool statistics
zpool iostat vault

# Dataset usage
zfs list vault

# ARC statistics
cat /proc/spl/kstat/zfs/arcstats | grep -E "(size|hits|miss)"
```

## Troubleshooting

### Common Issues

#### Pool Creation Fails
```bash
# Check if drives are busy
lsof /dev/disk/by-id/DRIVE-ID

# Force unmount if needed
sudo umount /dev/disk/by-id/DRIVE-ID

# Check for existing ZFS labels
sudo zdb -l /dev/disk/by-id/DRIVE-ID
```

#### Mount Issues
```bash
# Manual mount if auto-mount fails
sudo zfs mount vault/system
sudo zfs mount vault/users
sudo zfs mount vault/media
sudo zfs mount vault/temp

# Check mount status
zfs mount
```

#### Permission Issues
```bash
# Fix directory permissions if needed
sudo chown root:root /mnt/vault/system
sudo chown root:root /mnt/vault/users
sudo chown root:root /mnt/vault/media
sudo chown root:root /mnt/vault/temp
```

## Emergency Procedures

### Pool Export/Import
```bash
# If system has issues, export pool
sudo zpool export vault

# Re-import pool
sudo zpool import vault

# Import with force if needed
sudo zpool import -f vault
```

### Rollback Configuration
```bash
# If NixOS config causes issues, rollback
sudo cp -r /etc/nixos.backup.YYYYMMDD/* /etc/nixos/
sudo nixos-rebuild switch
```

### Recovery Boot
- If system doesn't boot, use NixOS rescue media
- Import pool in rescue environment
- Fix configuration and rebuild

## Success Criteria Checklist

- [ ] Pool 'vault' created successfully with mirror topology
- [ ] All 4 datasets created with correct properties
- [ ] Mount points working at /mnt/vault/*
- [ ] Directory structure created correctly
- [ ] Snapshots functioning
- [ ] No errors in `zpool status vault`
- [ ] System boots normally with ZFS support
- [ ] Network connectivity maintained
- [ ] Performance acceptable for test workloads

## Notes

- All commands assume you're running as a user with sudo privileges
- Drive IDs must be obtained from your specific system
- Backup current configuration before any changes
- Test thoroughly before proceeding to Home Manager setup
- Keep rescue media available during implementation