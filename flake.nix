{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steam-config-nix = {
      url = "github:different-name/steam-config-nix";
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
    wayvr-openxr-actions = {
      url = "https://raw.githubusercontent.com/wlx-team/wayvr/refs/heads/main/wayvr/src/backend/openxr/openxr_actions.json5";
      flake = false;
    };
    nixpkgs-update.url = "github:ryantm/nixpkgs-update";
    buttplug-lite = {
      url = "github:runtime-shady-backroom/buttplug-lite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nix-gaming-edge = {
      url = "github:powerofthe69/nix-gaming-edge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
    direnv-instant.url = "github:Mic92/direnv-instant";
    nixpkgs-patch-cinny-tauri-v2 = {
      url = "https://github.com/NixOS/nixpkgs/pull/470975.diff";
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
          inputs.niri.nixosModules.niri
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
          inputs.niri.nixosModules.niri
          ./hosts/Gertrude
        ];

        specialArgs = inputs;
      };

      packages.x86_64-linux =
        let
          system = "x86_64-linux";
          nixpkgs-patched = nixpkgs-patcher.lib.patchNixpkgs { inherit inputs system; };
          pkgs-patched = import nixpkgs-patched {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        in
        {
          baballonia = pkgs-patched.callPackage ./pkgs/baballonia { };
        };
    };
}
