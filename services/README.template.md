# [Service Name]

## Service Overview
- **Purpose**: Brief description of what this service does and why it's needed in the homelab
- **Category**: media | infrastructure | observability | self-hosting
- **Service Tier**: Critical | Important | Optional
- **External Access**: Yes/No - Brief description if externally accessible
- **Remote URL**: `[subdomain].halfblown.dev` (if applicable)

## Service Classification
- **Service User**: `[service-user-name]` 
- **Domain Group**: Based on category - `media`, `infrastructure`, `observability`, or `[service-name]` for self-hosting
- **Pipeline Role** (for media services): Where this fits in the media processing pipeline
- **Dependencies**: List key services this depends on

## Storage Requirements
**Fast Storage (NVMe)**:
- **Config/Database**: `/opt/homelab/services/[service]/` - Service configuration and databases
- **Local Logs**: `/var/log/homelab/[service]/` - Fast local logging
- **Cache**: Any caching needs on fast storage

**Bulk Storage (ZFS vault)**: 
- **Data Storage**: `/mnt/vault/[category]/[service]/` - Primary data storage
- **Temp/Processing**: Any temporary or processing storage needs

**Storage Access**: Based on domain group permissions from home-manager.md
- **Read/Write**: [Specific paths this service needs RW access]
- **Read-Only**: [Specific paths this service needs read access]

## Container Requirements
**Resource Limits**:
- **CPU**: Minimum and recommended CPU allocation (e.g., 0.5-2.0 cores)
- **Memory**: Minimum and recommended memory (e.g., 512MB-2GB)
- **Special Requirements**: GPU access, host networking, privileged mode, etc.

**Container Configuration**:
- **PUID/PGID**: Service-specific user and domain group IDs
- **Network Mode**: bridge (default) | host | VPN-isolated via Gluetun
- **Restart Policy**: unless-stopped | always | on-failure
- **Volume Strategy**: What data needs to persist vs what can be ephemeral

## Environment Configuration
```bash
# Service Identity
PUID=[service-uid]
PGID=[domain-group-gid]
TZ=America/Los_Angeles

# Service Configuration
[SERVICE]_KEY=value
[SERVICE]_API_KEY=api_key_for_integrations
[SERVICE]_URL_BASE=/[service]  # If using reverse proxy
# ... Any Additional service-specific environment variables for configuration

# Storage Paths (container perspective)
CONFIG_PATH=/config
DATA_PATH=/data
LOGS_PATH=/logs
```

## Network & Integration
**Network Requirements**:
- **Internal Ports**: Primary service port and any additional ports needed
- **External Ports**: Ports that need external access (if any)
- **Network Isolation**: Whether service uses default network, VPN, or host networking

**Service Integration**:
- **API Endpoints**: Key internal APIs this service provides
- **Depends On**: Services this container needs to communicate with
- **Used By**: Services that depend on this container
- **Profilarr Integration**: Whether service uses centralized quality management (for *arr services)

## Observability & Health
**Health Monitoring**:
- **Health Check**: How to verify service is running correctly
- **Key Metrics**: Important metrics to monitor (if service provides them)
- **Log Analysis**: What to look for in logs for health/issues

**Alloy Integration**:
- **Log Collection**: How Alloy should collect logs from this service
- **Metrics Collection**: Whether service provides Prometheus metrics
- **Alert Conditions**: What conditions should trigger alerts

## Backup & Maintenance
**Backup Requirements**:
- **Critical Data**: What data is essential and needs backup
- **Configuration**: How service configuration is preserved
- **Recovery**: Basic recovery procedures if service fails

**Maintenance**:
- **Updates**: How often to update container images
- **Cleanup**: Any regular cleanup tasks needed
- **Performance**: Key performance indicators to monitor

## Security Considerations
**Basic Security**:
- **Access Control**: How external access is controlled (Cloudflare Zero Trust)
- **Internal Security**: Basic container security (user context, no unnecessary privileges)
- **Secrets**: How API keys and passwords are managed
- **Network Security**: Network isolation and access restrictions

## Common Issues & Troubleshooting
**Startup Issues**:
- Common configuration problems and solutions
- Permission issues and fixes
- Dependency problems

**Runtime Issues**:
- Performance problems and solutions
- Common error patterns in logs
- Service recovery procedures

## Acceptance Criteria
**Deployment Success**:
- [ ] Container starts successfully and stays running
- [ ] Service accessible on expected ports
- [ ] Integration with dependencies working
- [ ] External access configured correctly (if applicable)
- [ ] Logging and monitoring functional

**Functional Validation**:
- [ ] Core service functionality working
- [ ] API endpoints responding (if applicable)
- [ ] Web interface accessible (if applicable)
- [ ] Service-specific functionality tests pass

## Notes
Add any service-specific quirks, important considerations, or special requirements here.