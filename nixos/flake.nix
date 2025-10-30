{
    description = "NixOS configuration for homelab-hl15";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    };

    outputs = { self, nixpkgs }: {
        nixosConfigurations.homelab-hl15 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
            ./configuration.nix
            ];
        };
    };
}
