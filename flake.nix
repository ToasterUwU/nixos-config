{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
      inputs.home-manager.follows = "home-manager";
    };
    catppuccin.url = "github:catppuccin/nix";
    nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
    nixpkgs-update.url = "github:ryantm/nixpkgs-update";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nix-gaming-edge = {
      url = "github:powerofthe69/nix-gaming-edge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steam-config-nix = {
      url = "github:different-name/steam-config-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:FlameFlag/nixcord";
    nix-vrft.url = "github:naraenda/nix-vrft";
    nixpkgs-patch-add-sable-dekstop-package = {
      url = "https://github.com/NixOS/nixpkgs/pull/548099.diff";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs-patcher,
      home-manager,
      catppuccin,
      agenix,
      nixpkgs-xr,
      nix-gaming-edge,
      niri,
      ...
    }@inputs:
    {
      nixosConfigurations.Barbara = nixpkgs-patcher.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          home-manager.nixosModules.home-manager
          catppuccin.nixosModules.catppuccin
          agenix.nixosModules.default
          nixpkgs-xr.nixosModules.nixpkgs-xr
          nix-gaming-edge.nixosModules.mesa-git
          niri.nixosModules.niri
          ./hosts/Barbara
        ];

        specialArgs = inputs;
      };
      nixosConfigurations.Gertrude = nixpkgs-patcher.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          home-manager.nixosModules.home-manager
          catppuccin.nixosModules.catppuccin
          agenix.nixosModules.default
          niri.nixosModules.niri
          ./hosts/Gertrude
        ];

        specialArgs = inputs;
      };
    };
}
