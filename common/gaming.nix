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
            elite-dangerous = {
              id = 359320;
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
            resonite = {
              id = 2519830;
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
            unravel-two = {
              id = 1225570;
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            mirrors-edge-catalyst = {
              id = 1233570;
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            burnout-paradise-remastered = {
              id = 1238080;
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            h3vr = {
              id = 450540;
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            space-engineers = {
              id = 244850;
              args = [ "-useallavailablecores" ];
            };
            overwatch = {
              id = 2357570;
              wrappers = [ "gamemoderun" ];
              env = {
                DXVK_CONFIG = "dxvk.trackPipelineLifetime = True;"; # Fixes a memeory leak issue
              };
            };
            stride = {
              id = 1292040;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            baballonia = {
              id = 4091970;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            beat-saber = {
              id = 620980;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            ghost-signal = {
              id = 2156770;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            the-last-clockwinder = {
              id = 1755100;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            underdogs = {
              id = 2441700;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            half-life-alyx = {
              id = 546560;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            space-pirate-trainer = {
              id = 418650;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            superhot-vr = {
              id = 617830;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            panoptic = {
              id = 541930;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            the-curious-tale-of-the-stolen-pets = {
              id = 1099500;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            myst = {
              id = 1255560;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            portal-stories-vr = {
              id = 446750;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            rumble = {
              id = 890550;
              env.PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
            };
            meccha-chameleon = {
              id = 4704690;
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
            eve-online = {
              # Remember to set to DirectX 11 in the Launcher
              id = 8500;
              compatTool = "proton_10";
              env = {
                PROTON_NO_ESYNC = 1;
                PROTON_NO_FSYNC = 1;
                LD_PRELOAD = "";
              };
              args = [ "--in-process-gpu" ];
            };
            titanfall-2 = {
              id = 1237970;
              # EA Launcher Fix
              preHook = ''
                for var in $(printenv | awk -F= 'length($2) > 2000 {print $1}');
                do
                  export $var=$(echo $\{!var} | rev | cut -c 1-2000 | rev);
                done
              '';
            };
            deltarune = {
              id = 1671210;
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
