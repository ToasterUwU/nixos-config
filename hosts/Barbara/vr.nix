{
  pkgs,
  lib,
  nix-gaming-edge,
  nixpkgs-xr,
  options,
  ...
}:
let
  isCachyOS = lib.any (pkg:
    if lib.isDerivation pkg then
      lib.hasInfix "cachyos" pkg.name
    else if lib.isAttrs pkg && pkg ? kernel then
      lib.hasInfix "cachyos" pkg.kernel.name
    else if lib.isAttrs pkg && pkg ? name then
      lib.hasInfix "cachyos" pkg.name
    else
      false
  ) options.boot.kernelPackages.definitions;
in
{
  nixpkgs.overlays = [
    nix-gaming-edge.overlays.mesa-git
    (final: prev: {
      monado = nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.overrideAttrs {
        cmakeFlags = (nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.cmakeFlags or [ ]) ++ [
          (lib.cmakeBool "XRT_BUILD_DRIVER_SOLARXR" true)
          (lib.cmakeBool "XRT_FEATURE_OPENXR_VISIBILITY_MASK" false)
        ];

        patches = (nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.patches or [ ]) ++ [
          (final.fetchpatch {
            url = "file://${../../assets/monado/solarxr-load-driver.diff}";
            hash = "sha256-gq2mvTrs1FCpNMRFkgaegePEzGFRcQpR1Z6QkqxdnqA=";
          })
        ];
      };
    })
  ];

  drivers.mesa-git = {
    enable = false;
  };

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;

  # Bigscreen Beyond Kernel patches from the LVRA Wiki
  boot.kernelPatches = [
    {
      # Fix for kernel bug
      name = "0001-drm-amdgpu-fix-check-in-amdgpu_hmm_invalidate_gfx";
      patch = ../../assets/kernel/0001-drm-amdgpu-fix-check-in-amdgpu_hmm_invalidate_gfx.patch;
    }
    {
      name = "0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSize";
      patch = ../../assets/kernel/0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSize.patch;
    }
  ] ++ lib.optionals (!isCachyOS) [
    {
      name = "amd-bsb-dsc-fix";
      patch = ../../assets/kernel/amd-bsb-dsc-fix.patch;
    }
    {
      name = "bigscreen-beyond-kernel-7.0.12";
      patch = ../../assets/kernel/bigscreen-beyond-kernel-7.0.12.patch;
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

  environment.systemPackages = with pkgs; [
    bs-manager
    wayvr
    xr-chaperone
    resolute
    lighthouse-steamvr
    monado-start
    buttplug-lite
    nrfconnect
    slimevr
  ];

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
      LH_OVERRIDE_IPD_MM = "64";
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
    };
  };
}
