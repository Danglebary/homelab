{ config, lib, pkgs, ... }:

{
    systemd.services.docker-containers-start = {
        description = "Service to start Docker containers on boot";

        after = [ "network-online.target" "docker.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        partOf = [ "docker.service" ];

        serviceConfig = {
            User = "root";
            Type = "oneshot";
            WorkingDirectory = "/opt/homelab";
            ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..10}; do docker info >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1'";
            ExecStart = "${pkgs.just}/bin/just docker-up";
            ExecStop = "${pkgs.just}/bin/just docker-down";
            RemainAfterExit = true;
            StandardOutput = "journal+console";
            StandardError = "journal+console";
        };
    }
}