{ config, lib, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.halfblown = {
    isNormalUser = true;
    description = "halfblown";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };
}
