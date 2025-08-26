# Cleanup Processing Group Module
# Allows deletion of old processing files for maintenance
# Used by admin user and future cleanup automation

{ config, lib, pkgs, ... }:

{
  users.groups.cleanup = {
    gid = 3025;  # Cleanup maintenance group
  };

  # No specific directories created - this group provides delete permissions
  # on existing temp/processing directories for maintenance tasks
}