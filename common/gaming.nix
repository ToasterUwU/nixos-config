{
  pkgs,
  lib,
  steam-config-nix,
  nix-cachyos-kernel,
  nix-gaming-edge,
  millennium,
  ...
}:
{
  nixpkgs.overlays = [
    nix-cachyos-kernel.overlays.pinned
    nix-gaming-edge.overlays.proton-cachyos
    millennium.overlays.default
  ];

  # CachyOS Kernel Substituter
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  services.hardware.openrgb.enable = true;
  services.ratbagd.enable = true;
  services.libinput.mouse.accelProfile = "flat";

  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  programs.gamemode.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      proton-cachyos-x86_64_v3
      dwproton-bin
    ];
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    protontricks.enable = true;
    package = pkgs.millennium-steam.override {
      extraProfile = ''
        unset TZ
        export PROTON_ENABLE_WAYLAND=1
        export PROTON_DXVK_LLASYNC=1
        export WINE_USE_TAKE_FOCUS=1
        export RADV_PERFTEST=sam,nircache,ngcc
        export ENABLE_LAYER_MESA_ANTI_LAG=1
        export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
        export __GL_SHADER_DISK_CACHE_SIZE=10737418240
        export PROTON_LOCAL_SHADER_CACHE=1
        export DXVK_ASYNC=1
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
      programs.steam = {
        config = {
          enable = true;
          onSteamRunning = "close";
          defaultCompatTool = "dwproton-x86_64";

          apps = {
            "359320" = {
              name = "Elite Dangerous";
              wrappers = [ "${lib.getExe pkgs.min-ed-launcher}" ];
              args = [
                "/autorun"
                "/autoquit"
                "/edo"
                "/vr"
                "/restart"
                "15"
              ];
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "2519830" = {
              name = "Resonite";
              wrappers = [ "gamemoderun" ];
              args = [
                "-Device"
                "SteamVR"
                "-ForceBabble"
                "-LoadAssembly"
                "Libraries/ResoniteModLoader.dll"
              ];
              env = {
                PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
                PROTON_USE_NTSYNC = 1;
              };
            };
            "1225570" = {
              name = "Unravel Two";
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            "1233570" = {
              name = "Mirror's Edge Catalyst";
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            "1238080" = {
              name = "Burnout Paradise Remastered";
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            "450540" = {
              name = "H3VR";
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "244850" = {
              name = "Space Engineers";
              args = [ "-useallavailablecores" ];
            };
            "2357570" = {
              name = "Overwatch 2";
              wrappers = [ "gamemoderun" ];
              env = {
                DXVK_CONFIG = "dxvk.trackPipelineLifetime = True;"; # Fixes a memeory leak issue
              };
            };
            "1292040" = {
              name = "STRIDE";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "4091970" = {
              name = "Baballonia";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "620980" = {
              name = "Beat Saber";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "2156770" = {
              name = "Ghost Signal";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "1755100" = {
              name = "The Last Clockwinder";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "2441700" = {
              name = "UNDERDOGS";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "546560" = {
              name = "Half-Life: Alyx";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "418650" = {
              name = "Space Pirate Trainer";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "617830" = {
              name = "SUPERHOT VR";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "541930" = {
              name = "Panoptic";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "1099500" = {
              name = "The Curious Tale of the Stolen Pets";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "1255560" = {
              name = "Myst";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "446750" = {
              name = "Portal Stories: VR";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "890550" = {
              name = "RUMBLE";
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            "4704690" = {
              name = "Meccha Chameleon";
              wrappers = [
                (lib.getExe pkgs.gamescope)
                "-W"
                "2560"
                "-H"
                "1440"
                "-f"
                "--force-grab-cursor"
                "--"
              ];
            };
            "8500" = {
              name = "EVE Online";
              compatTool = "proton_10";
              env = {
                PROTON_NO_ESYNC = 1;
                PROTON_NO_FSYNC = 1;
                LD_PRELOAD = "";
              };
              args = [ "--in-process-gpu" ];
            };
            "1237970" = {
              name = "Titanfall 2";
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            "1671210" = {
              name = "DELTARUNE";
              wrappers = [
                (lib.getExe pkgs.gamescope)
                "-W"
                "2560"
                "-H"
                "1440"
                "-f"
                "--"
              ];
            };
          };
        };
      };
    };
  };
}
