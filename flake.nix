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
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    direnv-instant.url = "github:Mic92/direnv-instant";
    nixcord.url = "github:FlameFlag/nixcord";
    nixpkgs-patch-fix-unityhub-missing-deps = {
      url = "https://github.com/NixOS/nixpkgs/pull/524422.diff";
      flake = false;
    };
    nixpkgs-patch-add-xr-chaperone = {
      url = "https://github.com/NixOS/nixpkgs/pull/513111.diff";
      flake = false;
    };
    nixpkgs-patch-add-cyberia-package = {
      url = "https://github.com/NixOS/nixpkgs/pull/515090.diff";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs-patcher,
      home-manager,
      catppuccin,
      agenix,
      arion,
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
          arion.nixosModules.arion
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
          arion.nixosModules.arion
          niri.nixosModules.niri
          ./hosts/Gertrude
        ];

        specialArgs = inputs;
      };
    };
}
