{
  description = "Flake for managing ThinkPad T14.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs_stable.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs_stable, home-manager, ... } @ inputs:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      t14 = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = { inherit nixpkgs_stable inputs; };
        
	    modules = [
          ./configuration.nix
	      inputs.home-manager.nixosModules.default
        ];
      };
    };
  };
}
