{ config, pkgs, ... }:

{
    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;

        daemon.settings = {
            # Use Cloudflare DNS for containers
            dns = [ "1.1.1.1" "1.0.0.1" ];

            # Enable iptables manipulation for container networking
            iptables = true;

            # Use default bridge network with our DNS
            bridge = "docker0";
        };
    };
}