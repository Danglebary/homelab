{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./network.nix
      ./localization.nix
      ./users/halfblown.nix
      ./users/admin.nix
      ./users/dev.nix
      ./ssh.nix
      ./zfs.nix
      ./docker.nix
      ./modules/default.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  # NOTE: commented out as zfs is marked as broken in latest kernel (6.16.2)
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable flakes support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
