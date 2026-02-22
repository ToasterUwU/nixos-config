{
  self,
  pkgs,
  lib,
  nix-gaming-edge,
  buttplug-lite,
  nixpkgs-xr,
  wayvr-openxr-actions,
  ...
}:
let
  patched_openxr_actions =
    pkgs.runCommand "openxr-actions-patched.json5"
      {
        buildInputs = [ pkgs.patch ];
        src = wayvr-openxr-actions;
      }
      ''
        cp $src openxr_actions.json5
        patch -s openxr_actions.json5 < ${../../assets/wayvr/openxr-actions-left-menu-show-hide.patch}
        mkdir -p $out
        cp openxr_actions.json5 $out/
      '';
in
{
  nixpkgs.overlays = [
    nix-gaming-edge.overlays.mesa-git
    (final: prev: {
      xrizer = nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.xrizer.overrideAttrs rec {
        src = pkgs.fetchFromGitHub {
          owner = "ImSapphire";
          repo = "xrizer";
          rev = "0046aae8bab66a6a7ad69d5dac481ea294e0a803";
          hash = "sha256-NnNYzoekeZeNQVoy8phcnWkyORFvxizDVkWGArg316g=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-orfK5pwWv91hA7Ra3Kk+isFTR+qMHSZ0EYZTVbf0fO0=";
        };
      };
      monado = nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.overrideAttrs {
        patches = (nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            name = "load-solarxr-driver";
            url = "https://gitlab.freedesktop.org/rcelyte/monado/-/commit/2cb76dd8e4743caaba616ef798ff2ddd4afb3b51.diff";
            hash = "sha256-Fmg8C3KpxzHDSmJDk9ph9vRSSfoIlUrEaX4k3S4keDU=";
          })
          (pkgs.fetchpatch {
            name = "solarxr-feeder-destroy-hooks";
            url = "https://gitlab.freedesktop.org/rcelyte/monado/-/commit/2ecd3fc0daff464d3d994608aec9c9f441e20c16.diff";
            hash = "sha256-ubbAaS1e1StkWSqLEd7iu2fiaBVW9WvonbV6uqBPBAk=";
          })
        ];

        cmakeFlags = (nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.cmakeFlags or [ ]) ++ [
          (lib.cmakeBool "XRT_FEATURE_OPENXR_VISIBILITY_MASK" false)
        ];
      };
    })
  ];

  drivers.mesa-git = {
    enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_6_18;

  # Bigscreen Beyond Kernel patches from LVRA Discord Thread
  boot.kernelPatches = [
    {
      name = "0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSize";
      patch = ../../assets/kernel/0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSize.patch;
    }
    {
      name = "0001-rename-VESA-block-parsing-functions-to-more-generic-name";
      patch = ../../assets/kernel/0001-rename-VESA-block-parsing-functions-to-more-generic-name.patch;
    }
    {
      name = "0002-prepare-for-VESA-vendor-specific-data-block-extension";
      patch = ../../assets/kernel/0002-prepare-for-VESA-vendor-specific-data-block-extension.patch;
    }
    {
      name = "0003-MSO-should-only-be-used-for-non-eDP-displays";
      patch = ../../assets/kernel/0003-MSO-should-only-be-used-for-non-eDP-displays.patch;
    }
    {
      name = "0004-parse-DSC-DPP-passthru-support-flag-for-mode-VII-timings";
      patch = ../../assets/kernel/0004-parse-DSC-DPP-passthru-support-flag-for-mode-VII-timings.patch;
    }
    {
      name = "0005-for-consistency-use-mask-everywhere-for-block-rev-parsing";
      patch = ../../assets/kernel/0005-for-consistency-use-mask-everywhere-for-block-rev-parsing.patch;
    }
    {
      name = "0006-parse-DRM-VESA-dsc-bpp-target";
      patch = ../../assets/kernel/0006-parse-DRM-VESA-dsc-bpp-target.patch;
    }
    {
      name = "0007-use-fixed-dsc-bits-per-pixel-from-edid";
      patch = ../../assets/kernel/0007-use-fixed-dsc-bits-per-pixel-from-edid.patch;
    }
  ];

  # Udev rules for Bigscreen devices
  services.udev.extraRules = ''
    # Bigscreen Beyond
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0101", MODE="0660", TAG+="uaccess", GROUP="wheel"
    # Bigscreen Bigeye
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0202", MODE="0660", TAG+="uaccess", GROUP="wheel"
    # Bigscreen Beyond Audio Strap
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0105", MODE="0660", TAG+="uaccess", GROUP="wheel"
    # Bigscreen Beyond Firmware Mode?
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="4004", MODE="0660", TAG+="uaccess", GROUP="wheel"

    # SlimeVR Dongle
    SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="7690", MODE="0666"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="7690", MODE="0666"

    # Slime Serial connections
    KERNEL=="ttyUSB[0-9]*",MODE="0666"
    KERNEL=="ttyACM[0-9]*",MODE="0666"
  '';

  programs.steam = {
    extraCompatPackages = with pkgs; [ proton-ge-rtsp-bin ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.segger-jlink.acceptLicense = true;

  environment.systemPackages =
    with pkgs;
    [
      bs-manager
      wayvr
      lovr-playspace
      resolute
      lighthouse-steamvr
      self.packages.x86_64-linux.baballonia
      monado-start
      nrfconnect
      slimevr
    ]
    ++ [ buttplug-lite.packages.x86_64-linux.default ];

  services.monado = {
    enable = true;
    defaultRuntime = true;
    highPriority = true;
  };

  systemd.user.services.monado = {
    serviceConfig = {
      LimitNOFILE = 8192;
      TimeoutStopSec = "5";
    };
    environment = {
      STEAMVR_LH_ENABLE = "true";
      XRT_COMPOSITOR_COMPUTE = "1";
      XRT_COMPOSITOR_SCALE_PERCENTAGE = "100";
      XRT_COMPOSITOR_DESIRED_MODE = "1";
      # XRT_COMPOSITOR_DESIRED_MODE=0 is the 75hz mode
      # XRT_COMPOSITOR_DESIRED_MODE=1 is the 90hz mode
    };
  };

  home-manager = {
    users.aki = {
      xdg.configFile."openxr/1/active_runtime.json".source = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
      xdg.configFile."openvr/openvrpaths.vrpath".text = ''
        {
          "config" :
          [
            "/home/aki/.local/share/Steam/config"
          ],
          "external_drivers" : null,
          "jsonid" : "vrpathreg",
          "log" :
          [
            "/home/aki/.local/share/Steam/logs"
          ],
          "runtime" :
          [
            "${pkgs.xrizer}/lib/xrizer",
            "/home/aki/.local/share/Steam/steamapps/common/SteamVR"
          ],
          "version" : 1
        }
      '';

      xdg.configFile."wayvr/conf.d/skybox.yaml".text = ''
        skybox_texture: ${../../assets/battlefront-2.dds}
      '';

      xdg.dataFile."LOVR/lovr-playspace/fade_start.txt".text = ''
        0.1
      '';
      xdg.dataFile."LOVR/lovr-playspace/fade_stop.txt".text = ''
        0.2
      '';

      xdg.configFile."wayvr/openxr_actions.json5".source = "${patched_openxr_actions}/openxr_actions.json5";
    };
  };
}
