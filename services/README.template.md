# [Service Name]

## Overview
**Purpose**: Brief description of what this service does and why it's needed
**Category**: Core Media | Infrastructure | Monitoring | Self-Hosting
**External Access**: Yes/No - Description of external access requirements

## Configuration

### Storage Requirements
- **Config/Database**: `/opt/homelab/services/[service]/` (NVMe)
- **Data Storage**: `/mnt/vault/[category]/[service]/` (ZFS) - if applicable
- **Logs**: `/var/log/homelab/[service]/` (NVMe, local fast logging)
- **Cache/Temp**: Description of temporary storage needs

### Environment Variables
```bash
# Required Environment Variables
VARIABLE_NAME=description_of_what_this_does
ANOTHER_VAR=TODO_description_needed

# Optional Environment Variables  
OPTIONAL_VAR=default_value_or_description

# User/Group IDs (service-specific)
PUID=TODO_service_specific_user_id  # Dedicated user for this service
PGID=TODO_service_group_id         # One of: media, infrastructure, observability, web
# Groups:
# - media: plex, sonarr-shows, sonarr-anime, radarr, tdarr, deluge, overseerr, profilarr, admin
# - infrastructure: pihole, gluetun, homepage, admin  
# - observability: prometheus, grafana, uptime-kuma, alloy, admin
# - web: immich, nextcloud

# Timezone
TZ=America/Los_Angeles

# Network Configuration
NETWORK_NAME=homelab_default
```

### Dependencies
- **Hard Dependencies**: Services that must be running first
- **Soft Dependencies**: Services that enhance functionality
- **External Dependencies**: Internet services, APIs, etc.

## Network Configuration
- **Network Mode**: bridge/host/custom
- **Ports**: List of exposed ports and their purposes
- **Internal Communication**: How this service talks to others
- **External Access**: Cloudflare Zero Trust tunnel details (if applicable)

## Hardware Requirements
- **CPU**: Specific CPU requirements or recommendations
- **Memory**: RAM requirements
- **GPU**: Hardware transcoding or acceleration needs (if applicable)
- **Storage I/O**: Performance requirements for storage

## Deployment

### Docker Compose Structure
```yaml
# TODO: Add complete docker-compose.yml content
services:
  service-name:
    image: TODO_image_name:tag
    container_name: service-name
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - TODO_config_volume
      - TODO_data_volumes
    networks:
      - TODO_network_name
    restart: unless-stopped
```

### Pre-deployment Steps
1. TODO: List any setup steps required before first deployment
2. TODO: Directory creation, permission setting, etc.
3. TODO: External service configuration

### Deployment Commands
```bash
# Navigate to homelab directory
cd /opt/homelab

# Copy environment template (first time only)
cp services/[service-name]/.env.example services/[service-name]/.env
# Edit .env with actual values
nano services/[service-name]/.env

# Deploy service using Just
just deploy [service-name]

# For services with instances (sonarr/radarr)
just deploy-sonarr shows
just deploy-sonarr anime
just deploy-radarr movies

# Verify deployment
just logs [service-name]
docker ps | grep [service-name]
```

## Integration Points

### Service Discovery
- **Internal URLs**: How other services connect to this one
- **API Endpoints**: Key API endpoints for integration
- **Authentication**: How authentication is handled between services

### Data Flow
- **Input**: What data this service receives and from where
- **Processing**: What this service does with the data
- **Output**: What data this service provides and to where

### Configuration Sync
- **Profilarr Integration**: If applicable, how quality profiles are managed
- **API Key Sharing**: How services authenticate with each other

## Telemetry & Observability

### Metrics Endpoints
- **Prometheus**: `http://service:port/metrics` - if available
- **Custom Metrics**: Description of service-specific metrics
- **Key Performance Indicators**: What metrics matter most

### Logging Configuration
- **Log Level**: How to configure verbosity
- **Log Format**: JSON/plain text/custom format
- **Log Location**: `/var/log/homelab/[service]/` (collected by Alloy)
- **Structured Logging**: Whether logs are machine-parseable

### Tracing Support
- **OpenTelemetry**: Whether service supports distributed tracing
- **Trace Endpoints**: How to configure trace export
- **Custom Spans**: Service-specific tracing capabilities

### Health Checks
- **Health Endpoint**: URL for liveness/readiness checks
- **Dependency Checks**: What dependencies are verified
- **Response Format**: Expected health check response

### Integration with Observability Stack
- **Alloy Collection**: How Alloy collects data from this service
- **Grafana Dashboards**: Available or planned dashboards
- **Alerting Rules**: What conditions should trigger alerts

## Monitoring & Health Checks

### Health Check Endpoints
- **URL**: `http://service:port/health` or similar
- **Expected Response**: What indicates the service is healthy
- **Dependencies Check**: How to verify dependent services are accessible

### Logging
- **Log Location**: Where logs are stored
- **Log Level Configuration**: How to adjust verbosity
- **Important Log Patterns**: What to look for in logs

### Metrics (if applicable)
- **Prometheus Endpoints**: Metrics exposed for monitoring
- **Key Metrics**: Important metrics to track
- **Alerting**: What conditions should trigger alerts

## Troubleshooting

### Common Issues
1. **Issue**: Description of common problem
   - **Symptoms**: How to identify this issue
   - **Cause**: Why this happens
   - **Solution**: Step-by-step fix

2. **TODO**: Document more issues as they're discovered

### Diagnostic Commands
```bash
# Check service status
docker compose ps

# View recent logs
docker compose logs --tail=50

# Check resource usage
docker stats container-name

# Verify network connectivity
docker exec container-name ping other-service

# TODO: Add service-specific diagnostic commands
```

### Recovery Procedures
1. **Restart Service**: `docker compose restart`
2. **Full Redeploy**: `docker compose down && docker compose up -d`
3. **Data Recovery**: TODO - document backup/restore procedures
4. **Configuration Reset**: TODO - document config reset steps

## Verification & Testing

### Post-Deployment Verification
1. **Service Accessibility**: 
   - [ ] Web interface accessible (if applicable)
   - [ ] API endpoints responding
   - [ ] Authentication working

2. **Integration Testing**:
   - [ ] Can communicate with dependent services
   - [ ] Data flow working correctly
   - [ ] External access functioning (if applicable)

3. **Performance Testing**:
   - [ ] Resource usage within expected limits
   - [ ] Response times acceptable
   - [ ] TODO: Service-specific performance tests

### Acceptance Criteria
- [ ] Service starts without errors
- [ ] All dependencies accessible
- [ ] Configuration applied correctly
- [ ] Integration points working
- [ ] External access configured (if applicable)
- [ ] Monitoring/alerting functional
- [ ] TODO: Add service-specific criteria

## Maintenance

### Regular Tasks
- **Weekly**: TODO - list weekly maintenance tasks
- **Monthly**: TODO - list monthly maintenance tasks
- **As Needed**: TODO - list situation-specific tasks

### Updates
- **Image Updates**: How to update the container image
- **Configuration Updates**: How to apply config changes
- **Data Migration**: Procedures for major version updates

### Backup Considerations
- **What to Backup**: Critical data and configuration
- **Backup Method**: How backups are performed
- **Restore Process**: How to restore from backup
- **TODO**: Document specific backup procedures

## Security Considerations

### Access Control
- **Authentication**: How users authenticate to this service
- **Authorization**: What permissions are required
- **Network Security**: Firewall rules, network isolation

### Data Protection
- **Sensitive Data**: What sensitive data this service handles
- **Encryption**: Data encryption at rest and in transit
- **Secrets Management**: How API keys and passwords are managed

### TODO Items
- [ ] Complete environment variable documentation
- [ ] Add specific Docker Compose configuration
- [ ] Document all integration points
- [ ] Add comprehensive troubleshooting guide
- [ ] Create backup/restore procedures
- [ ] Define monitoring and alerting rules
- [ ] Document security hardening steps
- [ ] Add performance tuning guidelines

## Notes
Add any service-specific notes, quirks, or important considerations here.