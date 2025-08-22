# ZFS Storage Requirements

## Overview
Comprehensive ZFS storage requirements for the HL15 homelab server to support media streaming, development workloads, service data, and telemetry storage with optimal performance, redundancy, and future expansion capabilities.

## Hardware Requirements

### Storage Hardware
- **Chassis**: HL15 2.0 with 15 hot-swap drive bays
- **Current Drives**: 2x Western Digital Ultrastar HC560 20TB SAS drives
- **Cache/SLOG Drives**: 2x 256GB NVMe SSDs for ZFS caching and SLOG acceleration
- **Expansion Capacity**: Support for up to 14 data drives + 1 hot spare
- **Drive Interface**: SAS connectivity for enterprise-grade reliability
- **Future Drives**: Additional drive pairs for expansion (20TB+ capacity recommended)

### System Requirements
- **RAM**: Minimum 64GB for ZFS ARC, recommended 128GB+ allocation
- **CPU**: Multi-core processor capable of handling ZFS checksumming and compression
- **Network**: Bonded 2.5GbE interface to handle concurrent media streaming and data access

## Pool Topology Requirements

### Pool Design: Mirror vdevs
**Topology**: Multiple 2-drive mirror vdevs in a single pool named "vault"

**Requirements Rationale:**
- **Performance**: Excellent read performance for media streaming workloads
- **Redundancy**: Each mirror vdev can lose 1 drive without data loss
- **Expansion**: Simple addition of new mirror vdevs as drive pairs are acquired
- **Flexibility**: Balanced approach for homelab use (not enterprise RAID-Z)
- **Random I/O**: Good performance for development databases and small file access

### Capacity Requirements
- **Initial**: 20TB usable storage (2 drives in mirror)
- **Maximum**: 140TB usable storage (14 drives in 7 mirror vdevs + 1 hot spare)
- **Growth Pattern**: Expand by adding drive pairs over time
- **Utilization Target**: Keep pool below 80% capacity for optimal performance

## Dataset Structure Requirements

### Primary Dataset Categories
```
vault/                          # Root dataset
├── media/                      # Media library storage
├── users/                      # User directories and personal data
├── temp/                       # Temporary storage and processing
├── telemetry/                  # Centralized observability data
├── immich/                     # Photo management service storage
└── nextcloud/                  # File sync service storage
```

### Media Storage Requirements (`vault/media/`)
**Purpose**: Permanent storage for Plex media libraries

**Content Organization:**
- `vault/media/movies/` - Non-anime movie content
- `vault/media/shows/` - Non-anime TV show content  
- `vault/media/anime/` - All anime content (both shows and movies)

**Performance Requirements:**
- Optimized for large sequential reads (Plex streaming)
- Support concurrent streaming to multiple clients
- Fast metadata access for library scanning

**Storage Characteristics:**
- Large files (1GB - 50GB+ per media file)
- Permanent retention (no automatic cleanup)
- Read-heavy workload with occasional writes during import

### User Storage Requirements (`vault/users/`)
**Purpose**: Personal user directories and development projects

**Content Organization:**
- `vault/users/admin/` - Admin user personal files and scripts
- `vault/users/dev/` - Development projects and personal Docker data

**Performance Requirements:**
- Good random I/O performance for development workflows
- Support for frequent small file operations
- Fast access for Docker container bind mounts

**Storage Characteristics:**
- Mixed file sizes (source code, databases, project files)
- Moderate retention with user-managed cleanup
- Read/write workload with development activity

### Temporary Storage Requirements (`vault/temp/`)
**Purpose**: Download processing, transcoding workspace, and staging

**Content Organization:**
- `vault/temp/downloads/` - Active and completed downloads
- `vault/temp/transcoding/` - Video transcoding workspace
- `vault/temp/transcoded/` - Processed media ready for import

**Performance Requirements:**
- High I/O performance for transcoding operations
- Fast sequential writes for downloads
- Quick file movement for media processing pipeline

**Storage Characteristics:**
- Large temporary files with automatic cleanup
- High turnover rate (files created and deleted frequently)
- Write-heavy workload during processing

### Telemetry Storage Requirements (`vault/telemetry/`)
**Purpose**: Centralized storage for logs, metrics, and observability data

**Content Organization:**
- `vault/telemetry/loki/` - Log data storage
- `vault/telemetry/metrics/` - Prometheus time-series data
- `vault/telemetry/grafana/` - Dashboard configurations
- `vault/telemetry/archived/` - Compressed historical data

**Performance Requirements:**
- Efficient time-series data storage and retrieval
- Support for log ingestion and querying workloads
- Good compression for long-term storage

**Storage Characteristics:**
- Time-series data with defined retention periods
- Write-heavy during collection, read-heavy during analysis
- Compression-friendly data types

### Immich Storage Requirements (`vault/immich/`)
**Purpose**: Photo and media storage for family photo management service

**Content Organization:**
- User photo libraries from family members
- Generated thumbnails and processed images
- Video content and associated metadata

**Performance Requirements:**
- Good performance for photo upload and processing
- Fast thumbnail generation and serving
- Efficient metadata operations

**Storage Characteristics:**
- Mixed media file sizes (photos, videos)
- Long-term retention of family memories
- Read-heavy workload with periodic uploads

### Nextcloud Storage Requirements (`vault/nextcloud/`)
**Purpose**: File synchronization and collaboration storage

**Content Organization:**
- User file synchronization directories
- Shared collaboration spaces
- Calendar, contacts, and notes data

**Performance Requirements:**
- Fast file synchronization operations
- Good performance for concurrent file access
- Efficient handling of small file updates

**Storage Characteristics:**
- Wide variety of file types and sizes
- User-managed retention and organization
- Mixed read/write workload with sync activity

## ZFS Feature Requirements

### Compression Requirements
**Media Dataset**: Minimal compression (gzip-1) due to already-compressed video files
**User Dataset**: Balanced compression (lz4) for good performance with mixed content
**Temp Dataset**: Fast compression (lz4) with performance priority
**Telemetry Dataset**: High compression (gzip-6) for log data efficiency
**Immich Dataset**: Minimal compression (lz4) for photo/video content
**Nextcloud Dataset**: Balanced compression (lz4) for mixed file types

### Snapshot Requirements
**Purpose**: ZFS snapshots provide point-in-time copies of data stored on the same pool for protection against accidental deletion, corruption, or configuration changes. Snapshots are NOT backups (they don't protect against hardware failure) but enable quick recovery from user errors.

**Usage Scenarios**:
- Hourly snapshots of user data for "oops I deleted something" recovery
- Daily snapshots before service updates for quick rollback capability  
- Weekly snapshots for longer-term accidental change recovery
- Automated cleanup to prevent snapshot storage buildup

**Benefits**:
- Instant, space-efficient point-in-time recovery
- Protection during system updates and configuration changes
- Quick rollback for development experiments gone wrong
- No additional hardware required

**Retention Policies**: Dataset-specific retention based on data criticality and change frequency
**Cross-Dataset Consistency**: Coordinated snapshots across related datasets when needed

### Performance Optimization Requirements
**Record Size Optimization**: Dataset-specific record sizes for workload characteristics
**ARC Management**: Proper ARC sizing for available RAM (128GB+ allocation)
**Prefetch**: Optimized prefetch settings for media streaming workloads
**Access Time**: Disabled atime for performance, enabled relatime where needed

### Data Integrity Requirements
**Checksumming**: Full data integrity verification for all datasets
**Scrubbing**: Regular scrub operations to detect and correct data corruption
**Redundancy**: Mirror-level redundancy with automatic repair capabilities
**Error Reporting**: Comprehensive error logging and alerting

## Access Control Requirements

### User Access Patterns
**Admin User**: Full read/write access to all datasets for system administration
**Dev User**: Read/write access to personal directories, read-only access to shared areas
**Service Users**: Limited access to service-specific subdirectories based on domain groups

### Service Access Requirements
**Media Services**: Read/write access to media and temp directories
**Observability Services**: Read/write access to telemetry directories
**Immich Service**: Read/write access to immich directory only
**Nextcloud Service**: Read/write access to nextcloud directory only

### Permission Model
**POSIX Permissions**: Standard Unix permissions for file-level access control
**Group-Based Access**: Domain groups (media, infrastructure, observability, web) for service isolation
**Directory Inheritance**: Proper permission inheritance for new files and directories

## Backup and Recovery Requirements

### Snapshot Strategy
**Frequency**: Automated snapshots based on data criticality and change rate
**Retention**: Tiered retention (hourly, daily, weekly, monthly) by dataset
**Storage**: Snapshot storage within the pool for instant recovery
**Cleanup**: Automatic snapshot cleanup based on retention policies

### Disaster Recovery
**Pool Export/Import**: Ability to move pool to different hardware
**Drive Replacement**: Hot-swappable drive replacement without downtime
**Data Recovery**: Recovery procedures for various failure scenarios
**Documentation**: Clear procedures for emergency recovery operations

## Monitoring and Alerting Requirements

### Health Monitoring
**Pool Status**: Continuous monitoring of pool and vdev health
**Drive Health**: SMART monitoring and predictive failure detection
**Capacity Monitoring**: Alerting before pool reaches capacity limits
**Performance Monitoring**: I/O statistics and bottleneck identification

### Error Detection
**Checksum Errors**: Detection and reporting of data corruption
**Device Errors**: Hardware-level error monitoring and alerting
**Scrub Results**: Regular scrub completion and error reporting
**Performance Degradation**: Detection of unusual performance patterns

## Expansion Requirements

### Growth Strategy
**Incremental Expansion**: Add drives in pairs to create new mirror vdevs
**Hot Spare Support**: Maintain one drive as hot spare for automatic replacement
**Capacity Planning**: Monitor growth trends and plan drive purchases
**Performance Scaling**: Ensure expansion maintains or improves performance

### Future Considerations
**Drive Technology**: Support for larger drives as they become available
**Interface Evolution**: Potential migration to newer drive interfaces
**Workload Changes**: Adaptation to evolving storage requirements
**Efficiency Improvements**: Ongoing optimization of storage utilization

## Security Requirements

### Network Security
**NFS Security**: Secure network file system access if implemented
**SMB Security**: Proper authentication for Windows file sharing
**Remote Access**: Secure remote administration through Tailscale
**Service Isolation**: Prevent unauthorized cross-service data access

## Performance Requirements

### Media Streaming
**Concurrent Streams**: Support multiple 4K HDR streams simultaneously
**Seek Performance**: Fast seeking and chapter navigation in media files
**Metadata Access**: Quick library scanning and metadata operations
**Transcoding Support**: High I/O performance during hardware transcoding

### Development Workloads
**Random I/O**: Good performance for database and development operations
**File Operations**: Fast file creation, modification, and deletion
**Container Storage**: Efficient Docker bind mount and volume performance
**Build Operations**: Support for intensive compilation and build processes

### System Operations
**Service Startup**: Fast loading of service configurations and data
**Log Processing**: Efficient log rotation and archival operations
**Backup Operations**: Minimal impact on system performance during backups
**Maintenance Tasks**: Performance during scrub and other maintenance operations

## Success Criteria

### Functional Requirements
- [ ] Pool creation successful with mirror topology
- [ ] All required datasets created with proper organization
- [ ] User and service access control implemented correctly
- [ ] Snapshot and retention policies operational
- [ ] Monitoring and alerting systems active

### Performance Requirements  
- [ ] Media streaming performance meets concurrent user needs
- [ ] Development workflow performance acceptable
- [ ] Service startup and operation performance adequate
- [ ] System maintenance operations do not significantly impact performance

### Reliability Requirements
- [ ] Data integrity verification through checksums operational
- [ ] Automatic error detection and reporting functional
- [ ] Drive failure recovery procedures tested
- [ ] Backup and recovery capabilities verified

### Operational Requirements
- [ ] Capacity monitoring and alerting configured
- [ ] Expansion procedures documented and tested
- [ ] Security controls implemented and verified
- [ ] Documentation complete and accessible

## Notes

- ZFS pool named "vault" reflects the secure, reliable storage nature of the homelab
- Mirror topology chosen for optimal balance of performance, redundancy, and expansion flexibility
- Dataset organization aligns with service requirements and user access patterns
- Performance optimizations tailored to specific workload characteristics
- Expansion strategy supports gradual growth without service interruption
- Security model integrates with overall homelab user and service architecture