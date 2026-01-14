# Homelab - HL15 Media Server & Self-Hosting Setup

A comprehensive homelab built on an HL15 2.0 server for media streaming and self-hosting services.

## What This Is

A production-quality homelab setup that provides:
- **Media Services**: Automated media management and streaming for friends and family
- **Self-Hosting Services**: Personal cloud services and file sharing
- **Remote Access**: Secure external access through Cloudflare Zero Trust
- **Modern Infrastructure**: Built with ZFS, NixOS, and containerized services

## Hardware

- **Server**: HL15 2.0 from 45HomeLab
- **Storage**: ZFS pool for media storage with NVMe drives for OS and configs
- **Network**: Bonded connection with managed switching
- **GPU**: Hardware transcoding support

## Technology Stack

- **OS**: NixOS with Flakes for declarative, reproducible configuration
- **Storage**: ZFS for data integrity, snapshots, and compression
- **Services**: systemd units with VPN namespace isolation
- **Remote Access**: Cloudflare tunnels for zero-trust access
- **Networking**: LACP bonding with VPN isolation for security

## Goals

Create a stable, maintainable homelab that friends and family can use for media streaming and file sharing. Focus on reliability and security over cutting-edge experimentation.