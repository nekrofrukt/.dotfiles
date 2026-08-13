{
  description = "Flake for managing Macbook Pro server.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs_stable.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    };
  };

  outputs = { self, nixpkgs, nixpkgs_stable, ... } @ inputs:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      nixbook = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = { inherit nixpkgs_stable inputs; };
        
	    modules = [
          ./configuration.nix
        ];
      };
    };
  };
}
