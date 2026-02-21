{
  pkgs,
  lib,
  steam-config-nix,
  nix-cachyos-kernel,
  nix-gaming-edge,
  ...
}:
{
  nixpkgs.overlays = [
    nix-cachyos-kernel.overlays.pinned
    nix-gaming-edge.overlays.proton-cachyos
  ];

  # CachyOS Kernel Substituter
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  services.hardware.openrgb.enable = true;
  services.ratbagd.enable = true;
  services.libinput.mouse.accelProfile = "flat";

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      proton-cachyos-x86_64_v4
    ];
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    protontricks.enable = true;
    package = pkgs.steam.override {
      extraProfile = ''
        unset TZ
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      '';
    };
  };

  programs.corectrl.enable = true;

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  environment.systemPackages = with pkgs; [
    piper
    wine
    wine64
    winetricks
    protonplus
    gale
    prismlauncher
    lutris
    pcsx2
    ed-odyssey-materials-helper
    edmarketconnector
    min-ed-launcher
    pyfa
  ];

  networking.hosts = {
    # "127.0.0.1" = [ "winter15.gosredirector.ea.com" ]; # A fix for "Mirrors Edge Catalyst". Without this it will try to ping a server that has been shutdown, then fail and crash
  };

  home-manager = {
    sharedModules = [ steam-config-nix.homeModules.default ];
    users.aki = {
      xdg.configFile."min-ed-launcher/settings.json".text = ''
          {
            "apiUri": "https://api.zaonce.net",
            "watchForCrashes": false,
            "language": null,
            "autoUpdate": true,
            "checkForLauncherUpdates": true,
            "maxConcurrentDownloads": 4,
            "forceUpdate": "",
            "processes": [
              {
                "fileName": "${lib.getExe pkgs.ed-odyssey-materials-helper}",
                "keepOpen": true
              },
              {
                "fileName": "${lib.getExe pkgs.edmarketconnector}",
                "keepOpen": true
              },
              {
                "fileName": "${lib.getExe pkgs.steam}",
                "arguments": "steam://rungameid/12396075390739677184",
                "keepOpen": true
              }
            ],
            "shutdownProcesses": [],
            "filterOverrides": [
                { "sku": "FORC-FDEV-DO-1000", "filter": "edo" },
                { "sku": "FORC-FDEV-DO-38-IN-40", "filter": "edh4" }
            ],
            "additionalProducts": []
        }
      '';
      programs.steam.config = {
        enable = true;
        closeSteam = true;
        defaultCompatTool = "Proton CachyOS x86_64-v4";

        apps = {
          elite-dangerous = {
            id = 359320;
            launchOptions = {
              wrappers = [ "${lib.getExe pkgs.min-ed-launcher}" ];
              args = [
                "/autorun"
                "/autoquit"
                "/edo"
                "/vr"
                "/restart"
                "15"
              ];
            };
          };
          resonite = {
            id = 2519830;
            compatTool = "Proton CachyOS x86_64-v4";
            launchOptions = {
              wrappers = [ "./run_monkeyloader.sh" ];
              args = [ "-Device" "SteamVR" ];
            };
          };
          unravel-two = {
            id = 1225570;
            # EA Launcher Fix
            launchOptions = {
              extraConfig = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
          };
          mirrors-edge-catalyst = {
            id = 1233570;
            # EA Launcher Fix
            launchOptions = {
              extraConfig = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
          };
          burnout-paradise-remastered = {
            id = 1238080;
            # EA Launcher Fix
            launchOptions = {
              extraConfig = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
          };
          h3vr = {
            id = 450540;
            launchOptions = {
              extraConfig = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
          };
          space-engineers = {
            id = 244850;
            launchOptions = {
              args = [ "-useallavailablecores" ];
            };
          };
        };
      };
    };
  };
}
