# [Service Name]

## Service Overview
- **Purpose**: Brief description of what this service does
- **Category**: media | infrastructure | observability | self-hosting
- **External Access**: Yes/No - `[subdomain].halfblown.dev` if applicable
- **Instance**: [shows/anime/movies] (for multi-instance services like Sonarr/Radarr)

## Service Configuration
- **User/Group**: `service:service` (UID: 2000, GID: 3000) OR `root` (if container requires root privileges)
- **Dependencies**: Services this depends on for startup
- **Pipeline Stage**: [request/search/download/transcode/import/serve] (media services only)

## Container Settings
**Ports**: [internal-port] (external access via Cloudflare tunnels)
**Resources**: [cpu-limits] CPU, [memory-limits] RAM
**Network**: bridge | host | container:gluetun
**Special Requirements**: GPU, privileged mode, etc.

## Environment Variables
```bash
# Timezone
TZ=America/Los_Angeles

# Service-Specific Configuration
# (Document actual environment variables this service needs)

# Storage Paths (if applicable)
# (Document container volume mount paths)
```

## Storage Access
**Read/Write Access**: List specific paths this service needs RW access to
**Read-Only Access**: List paths this service needs read access to

## Health Check
**Startup**: How to verify service started correctly
**Runtime**: Key indicators service is working properly
**Common Issues**: Most likely problems and quick fixes

## Notes
Service-specific quirks, configuration tips, or important considerations.