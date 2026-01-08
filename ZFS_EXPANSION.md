# ZFS Pool Expansion Guide

This guide explains the current ZFS pool architecture and provides step-by-step instructions for expanding the pool by adding additional mirror vdevs.

## Current Pool Architecture

### Overview

The homelab ZFS pool named `vault` uses a **mirror vdev architecture**:

```
Pool: vault
├── vdev0: MIRROR (2x 20TB drives)
│   ├── Drive 1: 20TB
│   └── Drive 2: 20TB (mirror of Drive 1)
│
└── Usable Capacity: 20TB
```

### What is a Mirror Vdev?

A **mirror vdev** (RAID1 equivalent) provides:
- **Redundancy**: All data is written to both drives simultaneously
- **Fault Tolerance**: Can lose one drive without data loss
- **Performance**: Fast reads (can read from either drive), good writes
- **Capacity**: 50% efficiency (2x 10TB drives = 10TB usable)

### Key Characteristics

- **Data Safety**: If one drive fails, all data remains accessible on the mirror
- **Hot Swappable**: Failed drives can be replaced while the system runs
- **Self-Healing**: ZFS automatically repairs corrupted data using the mirror copy
- **Performance**: Excellent for media server workloads (streaming, transcoding)

---

## How ZFS Pool Expansion Works

### Vdev-Based Architecture

ZFS pools grow by adding **additional vdevs**, not by adding drives to existing vdevs.

**Current pool:**
```
vault = vdev0 (20TB usable)
```

**After expansion with 2 new drives:**
```
vault = vdev0 (20TB) + vdev1 (10TB)
Total usable = 30TB
```

**After expansion with 4 new drives (2 mirror vdevs):**
```
vault = vdev0 (20TB) + vdev1 (10TB) + vdev2 (10TB)
Total usable = 40TB
```

### Important Constraints

1. **Cannot remove vdevs**: Once added, vdevs are permanent (can only remove by destroying the pool)
2. **Cannot change vdev type**: Cannot convert mirror to raidz or vice versa
3. **Data distribution**: ZFS stripes data across all vdevs proportional to their free space
4. **Performance**: Pool performance is limited by the slowest vdev

### Best Practice: Match Vdev Types

For optimal performance and predictability, all vdevs in a pool should use the **same topology**:
- If starting with mirrors, add more mirrors ✓
- Avoid mixing mirror + raidz in the same pool ✗

---

## Expansion Planning

### Determine How Many Drives You Have

Count the new drives you want to add. Mirrors require pairs:
- **2 drives** = 1 mirror vdev
- **4 drives** = 2 mirror vdevs
- **6 drives** = 3 mirror vdevs
- **8 drives** = 4 mirror vdevs

### Calculate Expected Capacity

Each mirror vdev provides usable capacity equal to **one drive's size**:

**Example with 6x 10TB drives:**
- 3 mirror vdevs = 3x 10TB usable = **30TB** added to pool
- Current 20TB + new 30TB = **50TB total usable**

### Consider Drive Sizes

ZFS allows mixed vdev sizes, but be aware:
- **Imbalanced vdevs** will distribute data proportionally
- **Smaller vdevs** may fill up faster
- **Best practice**: Use same-size drives within a vdev, similar sizes across vdevs

---

## Pre-Expansion Checklist

Before adding drives to your pool, complete these safety steps:

### 1. Backup Critical Data

While ZFS expansion is safe, always have backups:
```bash
# Snapshot current state
sudo zfs snapshot -r vault@pre-expansion

# Optional: Send snapshot to external backup
sudo zfs send -R vault@pre-expansion | ssh backup-server zfs receive backup/vault
```

### 2. Verify Current Pool Health

Ensure the pool is healthy before expanding:
```bash
# Check pool status
sudo zpool status vault

# Check for errors
sudo zpool status -x

# Run a scrub to verify data integrity
sudo zpool scrub vault

# Wait for scrub to complete
watch -n 5 'sudo zpool status vault'
```

**Expected output:**
- State: ONLINE
- Scan: scrub repaired 0B in HH:MM:SS with 0 errors
- Errors: No known data errors

### 3. Check Available Space

Verify you have some free space (recommended >10% free):
```bash
sudo zpool list vault
```

### 4. Identify New Drives

List all drives and identify the new ones:
```bash
# List all drives by ID (most reliable)
ls -la /dev/disk/by-id/ | grep -v part | grep -v dm

# List drive models and serial numbers
lsblk -o NAME,MODEL,SERIAL,SIZE

# Detailed info including SMART status
sudo smartctl -i /dev/sdX
```

**Important:**
- Use `/dev/disk/by-id/` paths (persistent across reboots)
- **Never use `/dev/sdX` paths** (can change on reboot)
- Verify drive serial numbers match your physical labels

### 5. Wipe New Drives (If Previously Used)

If drives have existing partitions or filesystems, wipe them:
```bash
# Check for existing data
sudo sgdisk --print /dev/disk/by-id/DRIVE-ID

# Wipe partition table (DESTRUCTIVE)
sudo sgdisk --zap-all /dev/disk/by-id/DRIVE-ID

# Wipe ZFS labels (if previously used for ZFS)
sudo zpool labelclear -f /dev/disk/by-id/DRIVE-ID
```

**⚠️ WARNING:** This destroys all data on the drive. Verify you have the correct drive!

---

## Expansion Procedure

### Step 1: Prepare Drive IDs

Create a list of your new drive IDs for easy reference:
```bash
# Example format - replace with your actual drive IDs
DRIVE1="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL1"
DRIVE2="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL2"
DRIVE3="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL3"
DRIVE4="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL4"
# ... etc
```

### Step 2: Verify Drive Pairing

Decide which drives form each mirror pair. Consider:
- **Physical location**: Mirror drives in different backplanes/controllers
- **Power supply**: Mirror drives on different power rails if possible
- **Drive batch**: Avoid pairing drives from the same manufacturing batch

**Example pairing strategy:**
- Mirror 1: Drive 1 (top bay, controller A) + Drive 2 (bottom bay, controller B)
- Mirror 2: Drive 3 (top bay, controller B) + Drive 4 (bottom bay, controller A)

### Step 3: Add Mirror Vdev(s) to Pool

The general syntax for adding mirror vdevs:
```bash
sudo zpool add POOL_NAME \
  mirror DRIVE1 DRIVE2 \
  mirror DRIVE3 DRIVE4 \
  mirror DRIVE5 DRIVE6
```

**For the vault pool with 2 drives (1 mirror vdev):**
```bash
sudo zpool add vault mirror $DRIVE1 $DRIVE2
```

**For the vault pool with 4 drives (2 mirror vdevs):**
```bash
sudo zpool add vault \
  mirror $DRIVE1 $DRIVE2 \
  mirror $DRIVE3 $DRIVE4
```

**For the vault pool with 6 drives (3 mirror vdevs):**
```bash
sudo zpool add vault \
  mirror $DRIVE1 $DRIVE2 \
  mirror $DRIVE3 $DRIVE4 \
  mirror $DRIVE5 $DRIVE6
```

### Step 4: Verify Expansion

Immediately after adding vdevs, verify the operation succeeded:

```bash
# Check pool status
sudo zpool status vault

# Check new capacity
sudo zpool list vault

# Verify all vdevs are ONLINE
sudo zpool status -v vault
```

**Expected output:**
```
  pool: vault
 state: ONLINE
config:

        NAME                    STATE     READ WRITE CKSUM
        vault                   ONLINE       0     0     0
          mirror-0              ONLINE       0     0     0
            ata-DRIVE_OLD1      ONLINE       0     0     0
            ata-DRIVE_OLD2      ONLINE       0     0     0
          mirror-1              ONLINE       0     0     0
            ata-DRIVE_NEW1      ONLINE       0     0     0
            ata-DRIVE_NEW2      ONLINE       0     0     0
          mirror-2              ONLINE       0     0     0
            ata-DRIVE_NEW3      ONLINE       0     0     0
            ata-DRIVE_NEW4      ONLINE       0     0     0
```

---

## Post-Expansion Steps

### 1. Run a Scrub

Verify data integrity across all vdevs:
```bash
sudo zpool scrub vault

# Monitor progress
watch -n 10 'sudo zpool status vault'
```

Wait for the scrub to complete. This may take several hours depending on pool size.

### 2. Verify New Capacity

Check that the pool shows the expected new capacity:
```bash
sudo zpool list -v vault
```

### 3. Update Monitoring

If using monitoring tools (Grafana, Prometheus, etc.), update them to track the new drives.

### 4. Document the Change

Record the expansion details:
- Date of expansion
- Drives added (model, serial numbers)
- New total capacity
- Purpose/reason for expansion

---

## Data Distribution and Balancing

### How ZFS Distributes Data

After adding vdevs, ZFS automatically:
- **Writes new data** evenly across all vdevs (proportional to free space)
- **Leaves existing data** on original vdevs

Over time, the pool will naturally balance as new data is written.

### Manual Rebalancing (Optional)

If you want to **immediately redistribute existing data** across all vdevs:

**Method 1: Copy and Delete**
```bash
# Create temporary directory on pool
sudo mkdir /mnt/vault/temp_rebalance

# Copy all data
sudo rsync -av --progress /mnt/vault/ /mnt/vault/temp_rebalance/

# Delete originals (after verifying copy)
sudo rm -rf /mnt/vault/original_dirs

# Move back
sudo mv /mnt/vault/temp_rebalance/* /mnt/vault/
```

**Method 2: ZFS Send/Receive (Advanced)**
```bash
# Snapshot current datasets
sudo zfs snapshot -r vault@rebalance

# Send to temporary location
sudo zfs send -R vault@rebalance | sudo zfs receive vault/temp

# Swap datasets (requires planning)
```

**⚠️ WARNING:** Manual rebalancing is generally **not necessary** and carries risk. Let ZFS naturally distribute data over time.

---

## Troubleshooting

### Issue: `cannot add to 'vault': pool must be upgraded`

**Cause:** Pool uses old ZFS feature flags

**Solution:**
```bash
# Upgrade pool (irreversible)
sudo zpool upgrade vault

# Verify
sudo zpool upgrade -v vault
```

### Issue: `invalid vdev specification: mirror contains devices of different sizes`

**Cause:** Drives in a mirror pair have different capacities

**Solution:**
- Ensure both drives in each mirror pair are the same size
- ZFS will use the smaller drive's capacity if mismatched
- Replace incorrect drive or adjust pairing

### Issue: `device is part of an active pool`

**Cause:** Drive was previously used in another ZFS pool

**Solution:**
```bash
# Force clear ZFS labels
sudo zpool labelclear -f /dev/disk/by-id/DRIVE-ID
```

### Issue: New vdevs show in pool but capacity didn't increase

**Cause:** Likely mismatched vdev types or drives already in pool

**Solution:**
```bash
# Check detailed pool status
sudo zpool status -v vault

# List all pool components
sudo zpool list -v vault

# Check for errors
sudo zpool status -x
```

### Issue: One drive in new mirror shows DEGRADED

**Cause:** Drive failure or connection issue

**Solution:**
```bash
# Check drive SMART status
sudo smartctl -a /dev/disk/by-id/DRIVE-ID

# Check kernel messages
sudo dmesg | grep -i error

# Replace failed drive
sudo zpool replace vault /dev/disk/by-id/OLD-DRIVE /dev/disk/by-id/NEW-DRIVE
```

---

## Recovery Procedures

### If Expansion Fails Mid-Operation

**ZFS expansion is atomic** - it either succeeds completely or rolls back.

If `zpool add` fails:
1. Check error message
2. Fix the issue (wrong drive ID, permission, etc.)
3. Retry the command
4. Pool remains unchanged until command succeeds

### If Pool Becomes Degraded After Expansion

```bash
# Check status
sudo zpool status vault

# Clear transient errors
sudo zpool clear vault

# If drive failed, replace it
sudo zpool replace vault /dev/disk/by-id/FAILED-DRIVE /dev/disk/by-id/NEW-DRIVE

# Monitor resilver progress
watch -n 10 'sudo zpool status vault'
```

### If You Need to Undo the Expansion

**⚠️ CRITICAL:** You **cannot remove vdevs** from a ZFS pool.

If you added the wrong drives or configuration:
1. **Option 1**: Destroy and recreate the pool (requires full restore from backup)
2. **Option 2**: Live with the configuration and plan better next time
3. **Option 3**: Migrate data to a new pool, then recreate original

**This is why pre-expansion verification is critical!**

---

## Best Practices Summary

### Before Expansion
- ✅ Backup critical data
- ✅ Verify pool health (scrub with 0 errors)
- ✅ Use `/dev/disk/by-id/` paths
- ✅ Verify drive serial numbers match physical labels
- ✅ Plan mirror pairs for fault tolerance

### During Expansion
- ✅ Double-check the `zpool add` command before executing
- ✅ Add all vdevs in a single command (avoids partial expansion)
- ✅ Monitor command output for errors

### After Expansion
- ✅ Verify pool status (all vdevs ONLINE)
- ✅ Run scrub to validate data integrity
- ✅ Document the change
- ✅ Update monitoring systems

### General Rules
- ✅ Match vdev types across the pool (all mirrors or all raidz)
- ✅ Use same-size drives within a mirror pair
- ✅ Distribute mirrors across physical failure domains
- ✅ Never use drives with existing important data
- ✅ Always have backups before making changes

---

## Example: Complete Expansion Workflow

Here's a complete example of adding 4 drives (2 mirror vdevs) to the vault pool:

```bash
# 1. Pre-expansion checks
sudo zpool status vault
sudo zpool scrub vault
# Wait for scrub to complete...

# 2. Identify drives
ls -la /dev/disk/by-id/ | grep ata-WDC

# 3. Set drive variables
DRIVE1="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL1"
DRIVE2="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL2"
DRIVE3="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL3"
DRIVE4="/dev/disk/by-id/ata-WDC_WD100EFAX_SERIAL4"

# 4. Verify drives are clean
sudo sgdisk --print $DRIVE1
sudo sgdisk --print $DRIVE2
sudo sgdisk --print $DRIVE3
sudo sgdisk --print $DRIVE4

# 5. Expand pool (THE CRITICAL COMMAND)
sudo zpool add vault \
  mirror $DRIVE1 $DRIVE2 \
  mirror $DRIVE3 $DRIVE4

# 6. Verify expansion
sudo zpool status vault
sudo zpool list vault

# 7. Post-expansion scrub
sudo zpool scrub vault

# 8. Monitor scrub progress
watch -n 10 'sudo zpool status vault'

# 9. Done! Document the change in your homelab notes
```

---

## References

- [ZFS Documentation - Pool Administration](https://openzfs.github.io/openzfs-docs/man/8/zpool-add.8.html)
- [Oracle ZFS Administration Guide](https://docs.oracle.com/cd/E19253-01/819-5461/gaynr/index.html)
- [NixOS ZFS Wiki](https://nixos.wiki/wiki/ZFS)

---

## Questions or Issues?

If you encounter problems during expansion:
1. **Do NOT panic** - ZFS expansion is very safe
2. **Do NOT force anything** - Read error messages carefully
3. **Check logs**: `sudo dmesg | tail -50` and `sudo journalctl -xe`
4. **Consult ZFS documentation** or community forums
5. **If in doubt, ask for help** before proceeding

Remember: The `zpool add` operation is **permanent and irreversible**. Take your time and verify every step.
