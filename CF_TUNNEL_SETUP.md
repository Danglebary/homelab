# Cloudflare Tunnel Setup Guide

This guide walks through the one-time setup process for creating and configuring a Cloudflare Zero Trust Tunnel for the homelab.

## Prerequisites

- Cloudflare account with a domain added
- NixOS configuration with cloudflared service defined
- Access to the server (SSH or console)

## Overview

The setup has two parts:
1. **One-time infrastructure provisioning** (creates the tunnel, generates credentials)
2. **Declarative configuration** (NixOS manages the runtime config)

---

## Part 1: One-Time Tunnel Creation

These steps are performed **once** to bootstrap the tunnel infrastructure.

### Step 1: Authenticate with Cloudflare

Run as the cloudflared service user:

```bash
sudo -u cloudflared cloudflared tunnel login
```

**What happens:**
- Outputs a URL like: `https://dash.cloudflare.com/argotunnel?callback=https://...`
- Open this URL in a browser (can be on your laptop/desktop, doesn't need to be on the server)
- Log in to your Cloudflare account
- Select the domain you want to use for the tunnel
- The server will detect the authorization and save `~/.cloudflared/cert.pem`

### Step 2: Create the Tunnel

```bash
sudo -u cloudflared cloudflared tunnel create homelab
```

Replace `homelab` with your preferred tunnel name.

**Expected output:**
```
Tunnel credentials written to /home/cloudflared/.cloudflared/a1b2c3d4-5678-90ab-cdef-1234567890ab.json
Created tunnel homelab with id a1b2c3d4-5678-90ab-cdef-1234567890ab
```

**Save the tunnel UUID** - you'll need it for the NixOS configuration!

### Step 3: Copy Credentials File

Move the auto-generated credentials file to the expected location:

```bash
# Replace UUID with your actual tunnel UUID from step 2
sudo cp /home/cloudflared/.cloudflared/a1b2c3d4-5678-90ab-cdef-1234567890ab.json \
       /var/lib/services/cloudflared/credentials.json

# Set proper ownership and permissions
sudo chown cloudflared:services /var/lib/services/cloudflared/credentials.json
sudo chmod 600 /var/lib/services/cloudflared/credentials.json
```

---

## Part 2: Update NixOS Configuration

### Step 4: Add Tunnel UUID to Config

Edit `nixos/modules/system/network/cloudflared.nix` and update the tunnel UUID in the declarative config:

```nix
environment.etc."cloudflared/config.yml".text = ''
  tunnel: a1b2c3d4-5678-90ab-cdef-1234567890ab  # Replace with your actual UUID
  credentials-file: /var/lib/services/cloudflared/credentials.json

  ingress:
    - hostname: requests.yourdomain.com  # Replace with your subdomain
      service: http://localhost:5055
    - service: http_status:404
'';
```

**Replace:**
- `a1b2c3d4-5678-90ab-cdef-1234567890ab` with your tunnel UUID from Step 2
- `requests.yourdomain.com` with your desired subdomain

### Step 5: Rebuild NixOS

Apply the configuration changes:

```bash
sudo nixos-rebuild switch
```

### Step 6: Start and Verify the Tunnel

```bash
# Start the tunnel service
sudo systemctl start cloudflared-tunnel

# Check status
sudo systemctl status cloudflared-tunnel

# View logs
sudo journalctl -u cloudflared-tunnel -f
```

**Success indicators:**
- Service status shows "active (running)"
- Logs show: "Connection established" or "Registered tunnel connection"
- No authentication errors

---

## Part 3: Configure DNS (Cloudflare Dashboard)

The tunnel is running, but you need to route traffic to it.

### Option A: Via Cloudflare Zero Trust Dashboard

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click on your tunnel (`homelab`)
4. Go to **Public Hostname** tab
5. Click **Add a public hostname**
6. Configure:
   - **Subdomain**: `requests`
   - **Domain**: `yourdomain.com`
   - **Service**: `http://localhost:5055`
7. Save

### Option B: Automatic (if using config.yml ingress)

If your `config.yml` includes the hostname, DNS should be automatically configured. Verify in the Cloudflare DNS dashboard that a CNAME record exists for `requests.yourdomain.com` pointing to your tunnel.

---

## Part 4: (Optional) Add Cloudflare Access Policy

To restrict access to authorized users only:

1. Go to **Access** → **Applications** → **Add an application**
2. Select **Self-hosted**
3. Configure:
   - **Application name**: `Overseerr`
   - **Application domain**: `requests.yourdomain.com`
4. Click **Next**
5. Create a policy:
   - **Policy name**: `Family and Friends`
   - **Action**: `Allow`
   - **Rule**: Add allowed emails or email domains
6. Save

Now only users matching your policy can access Overseerr.

---

## Adding More Services to the Tunnel

To expose additional services (like Plex), update the `ingress` section in `cloudflared.nix`:

```nix
environment.etc."cloudflared/config.yml".text = ''
  tunnel: a1b2c3d4-5678-90ab-cdef-1234567890ab
  credentials-file: /var/lib/services/cloudflared/credentials.json

  ingress:
    # Overseerr
    - hostname: requests.yourdomain.com
      service: http://localhost:5055

    # Plex
    - hostname: plex.yourdomain.com
      service: http://localhost:32400

    # Catch-all (required)
    - service: http_status:404
'';
```

Then:
1. Rebuild NixOS: `sudo nixos-rebuild switch`
2. Restart cloudflared: `sudo systemctl restart cloudflared-tunnel`
3. Add the public hostname in the Cloudflare dashboard (if needed)

---

## Troubleshooting

### Tunnel won't authenticate

**Problem**: `failed to authenticate` errors

**Solution**:
- Verify `credentials.json` exists at `/var/lib/services/cloudflared/credentials.json`
- Check file permissions: `ls -la /var/lib/services/cloudflared/credentials.json`
- Ensure ownership is `cloudflared:services` and permissions are `600`

### Can't access the service remotely

**Problem**: Tunnel is running but hostname returns 404 or timeout

**Solution**:
- Verify DNS record exists: `dig requests.yourdomain.com`
- Check service is running locally: `curl http://localhost:5055`
- Verify ingress rules in config match the hostname
- Check cloudflared logs: `journalctl -u cloudflared-tunnel -n 50`

### Service restarts frequently

**Problem**: `systemctl status cloudflared-tunnel` shows constant restarts

**Solution**:
- Check logs for errors: `journalctl -u cloudflared-tunnel -f`
- Common issues:
  - Invalid tunnel UUID in config
  - Missing or corrupted credentials file
  - Network connectivity issues

### Need to recreate the tunnel

If you need to start over:

```bash
# Delete the tunnel
sudo -u cloudflared cloudflared tunnel delete homelab

# Then follow the setup steps again from Step 2
```

---

## File Locations Reference

| File                                             | Purpose                               | Created By                  |
| ------------------------------------------------ | ------------------------------------- | --------------------------- |
| `~/.cloudflared/cert.pem`                        | Account authentication certificate    | `cloudflared tunnel login`  |
| `~/.cloudflared/<UUID>.json`                     | Tunnel credentials (original)         | `cloudflared tunnel create` |
| `/var/lib/services/cloudflared/credentials.json` | Tunnel credentials (runtime location) | Manual copy                 |
| `/etc/cloudflared/config.yml`                    | Tunnel configuration                  | NixOS (declarative)         |

---

## Security Notes

- **Never commit** `credentials.json` to git
- Keep `credentials.json` permissions at `600` (owner read/write only)
- Consider using Cloudflare Access policies to restrict who can access services
- Rotate tunnel credentials if compromised: delete and recreate the tunnel

---

## Summary

**One-time setup:**
1. `cloudflared tunnel login` (authenticate)
2. `cloudflared tunnel create homelab` (create tunnel, get UUID)
3. Copy credentials to `/var/lib/services/cloudflared/credentials.json`

**NixOS configuration:**
4. Add tunnel UUID to `cloudflared.nix`
5. `nixos-rebuild switch`
6. Configure DNS/hostnames in Cloudflare dashboard

**Done!** Your services are now securely accessible via Cloudflare Zero Trust Tunnel.
