{
  description = "configuration.nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs = inputs@{ nixpkgs, home-manager, vpn-confinement, ... }: let variables = import ./variables.nix; in {
    nixosConfigurations = {
      "${variables.hostname}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          # make home-manager as a module of nixos so that home-manager
          # configuration will be deployed automatically when executing
          # `nixos-rebuild switch`
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit variables; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${variables.username}" = import ./home/home.nix;
          }

          vpn-confinement.nixosModules.default
        ];
      specialArgs = { inherit variables; };
      };
    };
  };
}
