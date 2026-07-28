{
  pkgs,
  lib,
  nix-gaming-edge,
  nixpkgs-xr,
  options,
  ...
}:
let
  isCachyOS = lib.any (
    pkg:
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

        patches = nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.patches ++ [
          (final.fetchpatch {
            url = "file://${../../assets/monado/solarxr-load-driver.diff}";
            hash = "sha256-Z3bsDQUWM0RUizKQzRZSKYPnggixEzrGxAMAVgsscaw=";
          })
          (final.fetchpatch {
            url = "file://${../../assets/monado/solarxr-feeder-destroy-hooks.diff}";
            hash = "sha256-djT5UMN/udueDHrS2x+wNw61OXo+svyAi0z+xpje+00=";
          })
        ];
      };
    })
  ];

  drivers.mesa-git = {
    enable = false;
  };

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;

  # Bigscreen Beyond Kernel patches from the LVRA Wiki
  boot.kernelPatches =
    [
      {
        name = "0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSize";
        patch = ../../assets/kernel/0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSize.patch;
      }
      {
        name = "disable-unused-drivers";
        patch = null;
        structuredExtraConfig = with lib.kernel; {
          # Disable Guest VM Virtualization Drivers (Host runs bare-metal, not as guest)
          HYPERVISOR_GUEST = lib.mkForce no;

          # Disable non-AMD GPU drivers
          DRM_I915 = lib.mkForce no;
          DRM_XE = lib.mkForce no;
          DRM_NOUVEAU = lib.mkForce no;
          DRM_RADEON = lib.mkForce no; # Legacy Radeon (non-amdgpu)
          DRM_GMA500 = lib.mkForce no;
          DRM_VMWGFX = lib.mkForce no;
          DRM_VIRTIO_GPU = lib.mkForce no;
          DRM_BOCHS = lib.mkForce no;
          DRM_XEN_FRONTEND = lib.mkForce no;
          DRM_VBOXVIDEO = lib.mkForce no;

          # Disable mobile broadband / cellular modems (LTE/5G)
          WWAN = lib.mkForce no;

          # Disable InfiniBand (high-performance networking not used here)
          INFINIBAND = lib.mkForce no;

          # Disable Laptop ACPI/Platform Drivers (keeping Gigabyte)
          ASUS_LAPTOP = lib.mkForce no;
          ASUS_WMI = lib.mkForce no;
          THINKPAD_ACPI = lib.mkForce no;
          DELL_LAPTOP = lib.mkForce no;
          DELL_WMI = lib.mkForce no;
          HP_WMI = lib.mkForce no;
          HP_ILO = lib.mkForce no;
          MSI_LAPTOP = lib.mkForce no;
          MSI_WMI = lib.mkForce no;
          SAMSUNG_LAPTOP = lib.mkForce no;
          SONY_LAPTOP = lib.mkForce no;
          TOSHIBA_WMI = lib.mkForce no;
          ACER_WMI = lib.mkForce no;
          COMPAL_LAPTOP = lib.mkForce no;
          FUJITSU_LAPTOP = lib.mkForce no;

          # Disable touchscreens and drawing tablets (no tablets are used)
          INPUT_TOUCHSCREEN = lib.mkForce no;
          TABLET_USB_ACECAD = lib.mkForce no;
          TABLET_USB_AIPTEK = lib.mkForce no;
          TABLET_USB_HANWANG = lib.mkForce no;
          TABLET_USB_KBTAB = lib.mkForce no;
          TABLET_USB_PEGASUS = lib.mkForce no;
          TABLET_SERIAL_WACOM4 = lib.mkForce no;
          INPUT_TABLET = lib.mkForce no;
          HID_WACOM = lib.mkForce no;

          # Disable TV Tuners, Radio, and SDR (Software Defined Radio)
          MEDIA_ANALOG_TV_SUPPORT = lib.mkForce no;
          MEDIA_DIGITAL_TV_SUPPORT = lib.mkForce no;
          MEDIA_RADIO_SUPPORT = lib.mkForce no;
          MEDIA_SDR_SUPPORT = lib.mkForce no;
          MEDIA_PCI_SUPPORT = lib.mkForce no;

          # Disable obsolete hardware interfaces / buses
          FIREWIRE = lib.mkForce no;
          PCMCIA = lib.mkForce no;
          PARPORT = lib.mkForce no;

          # Disable enterprise/datacentre storage controllers
          SCSI_LOWLEVEL = lib.mkForce no;
          SCSI_AACRAID = lib.mkForce no;
          SCSI_AIC7XXX = lib.mkForce no;
          SCSI_AIC79XX = lib.mkForce no;
          SCSI_AIC94XX = lib.mkForce no;
          SCSI_MVSAS = lib.mkForce no;
          SCSI_MPT2SAS = lib.mkForce no;
          SCSI_MPT3SAS = lib.mkForce no;
          SCSI_ISCI = lib.mkForce no;
          SCSI_PM8001 = lib.mkForce no;
          SCSI_UFSHCD = lib.mkForce no;
          MEGARAID_NEWGEN = lib.mkForce no;
          MEGARAID_MM = lib.mkForce no;
          MEGARAID_MAILBOX = lib.mkForce no;
          MEGARAID_LEGACY = lib.mkForce no;
          MEGARAID_SAS = lib.mkForce no;
          FUSION = lib.mkForce no;
          SCSI_QLA_FC = lib.mkForce no;

          # Disable enterprise Mellanox network drivers
          MLX4_CORE = lib.mkForce no;
          MLX5_CORE = lib.mkForce no;

          # Disable Chromebook platforms
          CHROME_PLATFORMS = lib.mkForce no;
        };
      }
    ]
    ++ lib.optionals (!isCachyOS) [
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
    etvr
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
      LH_DISCOVER_WAIT_MS = "10000";
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
