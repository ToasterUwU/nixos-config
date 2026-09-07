{
  pkgs,
  lib,
  nix-vrft,
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
    nix-vrft.overlays.pinned
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

      # Use the nixpkgs package instead of the nixpkgs-xr one, which does not
      # install the .desktop file or icons.
      xr-chaperone = final.callPackage "${final.path}/pkgs/by-name/xr/xr-chaperone/package.nix" { };
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
        # Trimmed to this machines hardware to cut kernel compile time. Failures here are silent. A "no" is ignored if something still selects the symbol
        structuredExtraConfig = with lib.kernel; {
          # Disable virtual machine guest drivers, this host runs on bare metal
          HYPERVISOR_GUEST = lib.mkForce no;

          # Disable graphics drivers other than AMD
          DRM_I915 = lib.mkForce no;
          DRM_XE = lib.mkForce no;
          DRM_NOUVEAU = lib.mkForce no;
          DRM_RADEON = lib.mkForce no; # Legacy Radeon, not amdgpu
          DRM_GMA500 = lib.mkForce no;
          DRM_VIRTIO_GPU = lib.mkForce no;
          DRM_BOCHS = lib.mkForce no;
          DRM_VBOXVIDEO = lib.mkForce no;

          # Other display hardware, DRM_SIMPLEDRM stays because it is the boot console
          DRM_UDL = lib.mkForce no; # DisplayLink USB adapters
          DRM_AST = lib.mkForce no; # ASPEED server management chip
          DRM_MGAG200 = lib.mkForce no; # Matrox server management chip
          DRM_CIRRUS_QEMU = lib.mkForce no;
          DRM_SSD130X = lib.mkForce no; # Tiny display panels
          DRM_ETNAVIV = lib.mkForce no; # Vivante embedded graphics
          DRM_HISI_HIBMC = lib.mkForce no;
          DRM_GUD = lib.mkForce no;
          # DRM_BRIDGE and DRM_PANEL cannot be set here, the panel drivers go away with OF below

          # Disable machine learning and compute accelerators
          DRM_ACCEL = lib.mkForce no;

          # Disable mobile broadband and cellular modems
          WWAN = lib.mkForce no;

          # Disable InfiniBand, this machine does not use it
          INFINIBAND = lib.mkForce no;

          # Ethernet, only the onboard Realtek RTL8125 is needed
          NET_VENDOR_3COM = lib.mkForce no;
          NET_VENDOR_8390 = lib.mkForce no;
          NET_VENDOR_ADAPTEC = lib.mkForce no;
          NET_VENDOR_ADI = lib.mkForce no;
          NET_VENDOR_AGERE = lib.mkForce no;
          NET_VENDOR_ALACRITECH = lib.mkForce no;
          NET_VENDOR_ALIBABA = lib.mkForce no;
          NET_VENDOR_AMAZON = lib.mkForce no;
          NET_VENDOR_AMD = lib.mkForce no;
          NET_VENDOR_AQUANTIA = lib.mkForce no;
          NET_VENDOR_ARC = lib.mkForce no;
          NET_VENDOR_ASIX = lib.mkForce no;
          NET_VENDOR_ATHEROS = lib.mkForce no;
          NET_VENDOR_BROADCOM = lib.mkForce no;
          NET_VENDOR_BROCADE = lib.mkForce no;
          NET_VENDOR_CADENCE = lib.mkForce no;
          NET_VENDOR_CAVIUM = lib.mkForce no;
          NET_VENDOR_CHELSIO = lib.mkForce no;
          NET_VENDOR_CISCO = lib.mkForce no;
          NET_VENDOR_CORTINA = lib.mkForce no;
          NET_VENDOR_DAVICOM = lib.mkForce no;
          NET_VENDOR_DEC = lib.mkForce no;
          NET_VENDOR_DLINK = lib.mkForce no;
          NET_VENDOR_EMULEX = lib.mkForce no;
          NET_VENDOR_ENGLEDER = lib.mkForce no;
          NET_VENDOR_EZCHIP = lib.mkForce no;
          NET_VENDOR_FUNGIBLE = lib.mkForce no;
          NET_VENDOR_GOOGLE = lib.mkForce no;
          NET_VENDOR_HISILICON = lib.mkForce no;
          NET_VENDOR_HUAWEI = lib.mkForce no;
          NET_VENDOR_I825XX = lib.mkForce no;
          NET_VENDOR_INTEL = lib.mkForce no;
          NET_VENDOR_LITEX = lib.mkForce no;
          NET_VENDOR_MARVELL = lib.mkForce no;
          NET_VENDOR_MELLANOX = lib.mkForce no; # replaces the old MLX4_CORE and MLX5_CORE lines
          NET_VENDOR_META = lib.mkForce no;
          NET_VENDOR_MICREL = lib.mkForce no;
          NET_VENDOR_MICROCHIP = lib.mkForce no;
          NET_VENDOR_MICROSEMI = lib.mkForce no;
          NET_VENDOR_MICROSOFT = lib.mkForce no;
          NET_VENDOR_MUCSE = lib.mkForce no;
          NET_VENDOR_MYRI = lib.mkForce no;
          NET_VENDOR_NATSEMI = lib.mkForce no;
          NET_VENDOR_NETRONOME = lib.mkForce no;
          NET_VENDOR_NI = lib.mkForce no;
          NET_VENDOR_NVIDIA = lib.mkForce no;
          NET_VENDOR_OKI = lib.mkForce no;
          NET_VENDOR_PENSANDO = lib.mkForce no;
          NET_VENDOR_QLOGIC = lib.mkForce no;
          NET_VENDOR_QUALCOMM = lib.mkForce no;
          NET_VENDOR_RDC = lib.mkForce no;
          NET_VENDOR_RENESAS = lib.mkForce no;
          NET_VENDOR_ROCKER = lib.mkForce no;
          NET_VENDOR_SAMSUNG = lib.mkForce no;
          NET_VENDOR_SEEQ = lib.mkForce no;
          NET_VENDOR_SILAN = lib.mkForce no;
          NET_VENDOR_SIS = lib.mkForce no;
          NET_VENDOR_SMSC = lib.mkForce no;
          NET_VENDOR_SOCIONEXT = lib.mkForce no;
          NET_VENDOR_SOLARFLARE = lib.mkForce no;
          NET_VENDOR_STMICRO = lib.mkForce no;
          NET_VENDOR_SUN = lib.mkForce no;
          NET_VENDOR_SYNOPSYS = lib.mkForce no;
          NET_VENDOR_TEHUTI = lib.mkForce no;
          NET_VENDOR_TI = lib.mkForce no;
          NET_VENDOR_VERTEXCOM = lib.mkForce no;
          NET_VENDOR_VIA = lib.mkForce no;
          NET_VENDOR_WANGXUN = lib.mkForce no;
          NET_VENDOR_WIZNET = lib.mkForce no;
          NET_VENDOR_XILINX = lib.mkForce no;

          # Wireless, only the MediaTek MT7922 is needed
          WLAN_VENDOR_ADMTEK = lib.mkForce no;
          WLAN_VENDOR_ATH = lib.mkForce no;
          WLAN_VENDOR_ATMEL = lib.mkForce no;
          WLAN_VENDOR_BROADCOM = lib.mkForce no;
          WLAN_VENDOR_INTEL = lib.mkForce no;
          WLAN_VENDOR_INTERSIL = lib.mkForce no;
          WLAN_VENDOR_MARVELL = lib.mkForce no;
          WLAN_VENDOR_MICROCHIP = lib.mkForce no;
          WLAN_VENDOR_PURELIFI = lib.mkForce no;
          WLAN_VENDOR_QUANTENNA = lib.mkForce no;
          WLAN_VENDOR_RALINK = lib.mkForce no;
          WLAN_VENDOR_REALTEK = lib.mkForce no;
          WLAN_VENDOR_RSI = lib.mkForce no;
          WLAN_VENDOR_SILABS = lib.mkForce no;
          WLAN_VENDOR_ST = lib.mkForce no;
          WLAN_VENDOR_TI = lib.mkForce no;
          WLAN_VENDOR_ZYDAS = lib.mkForce no;

          # Of the MediaTek parts, only MT7921E is fitted
          MT7601U = lib.mkForce no;
          MT76x0U = lib.mkForce no;
          MT76x0E = lib.mkForce no;
          MT76x2E = lib.mkForce no;
          MT76x2U = lib.mkForce no;
          MT7603E = lib.mkForce no;
          MT7615E = lib.mkForce no;
          MT7663U = lib.mkForce no;
          MT7663S = lib.mkForce no;
          MT7915E = lib.mkForce no;
          MT7925E = lib.mkForce no;
          MT7925U = lib.mkForce no;
          MT7921S = lib.mkForce no;
          MT7921U = lib.mkForce no;
          MT7996E = lib.mkForce no;

          # Disable other vendor platform drivers. The Gigabyte one is not listed because it reads the board temperature sensors.
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
          SURFACE_PLATFORMS = lib.mkForce no;

          # Disable touchscreens and drawing tablets (no tablets are used)
          INPUT_TOUCHSCREEN = lib.mkForce no;
          INPUT_TABLET = lib.mkForce no;
          HID_WACOM = lib.mkForce no;

          # Disable television tuners, radio and software defined radio
          MEDIA_ANALOG_TV_SUPPORT = lib.mkForce no;
          MEDIA_DIGITAL_TV_SUPPORT = lib.mkForce no;
          MEDIA_RADIO_SUPPORT = lib.mkForce no;
          MEDIA_SDR_SUPPORT = lib.mkForce no;
          MEDIA_PCI_SUPPORT = lib.mkForce no;

          # Media, only USB video cameras are used, so the rest can go
          MEDIA_PLATFORM_SUPPORT = lib.mkForce no; # Capture and codec blocks built into other chips
          VIDEO_CAMERA_SENSOR = lib.mkForce no; # Camera sensor drivers
          MEDIA_TEST_SUPPORT = lib.mkForce no;
          V4L_TEST_DRIVERS = lib.mkForce no;
          USB_GSPCA = lib.mkForce no; # Older webcams that predate the USB video standard

          # Audio, only the onboard audio and USB audio are used
          SND_SOC = lib.mkForce no; # Embedded and laptop codec platforms
          SND_PCI = lib.mkForce no;
          SND_VIRTIO = lib.mkForce no;
          SND_HDA_CODEC_ANALOG = lib.mkForce no;
          SND_HDA_CODEC_SIGMATEL = lib.mkForce no;
          SND_HDA_CODEC_VIA = lib.mkForce no;
          SND_HDA_CODEC_CONEXANT = lib.mkForce no;
          SND_HDA_CODEC_CIRRUS = lib.mkForce no;
          SND_HDA_CODEC_CA0132 = lib.mkForce no;
          SND_HDA_CODEC_CMEDIA = lib.mkForce no;
          SND_HDA_CODEC_HDMI_NVIDIA = lib.mkForce no;
          SND_HDA_CODEC_HDMI_INTEL = lib.mkForce no;
          SND_HDA_CODEC_HDMI_TEGRA = lib.mkForce no;

          # Disable obsolete hardware interfaces and buses
          FIREWIRE = lib.mkForce no;
          PCMCIA = lib.mkForce no;
          PARPORT = lib.mkForce no;

          # Embedded USB host controllers. The older ones stay because the NixOS initrd needs them
          USB_R8A66597_HCD = lib.mkForce no;
          USB_MAX3421_HCD = lib.mkForce no;
          USB_SL811_HCD = lib.mkForce no;
          USB_ISP116X_HCD = lib.mkForce no;
          USB_C67X00_HCD = lib.mkForce no;
          USB_OXU210HP_HCD = lib.mkForce no;

          # No USB gadget hardware
          USB_GADGET = lib.mkForce no;

          # Disable enterprise and datacentre storage controllers
          SCSI_LOWLEVEL = lib.mkForce no;
          SCSI_UFSHCD = lib.mkForce no;
          FUSION = lib.mkForce no;

          # Disable Chromebook platforms
          CHROME_PLATFORMS = lib.mkForce no;

          # Large subsystems with no matching hardware
          IIO = lib.mkForce no;
          HID_MCP2221 = lib.mkForce no; # selects IIO, so it has to go too
          STAGING = lib.mkForce no;
          COMEDI = lib.mkForce no; # lab data-acquisition cards
          MTD = lib.mkForce no; # raw flash memory
          SECURITY_SELINUX = lib.mkForce no; # NixOS uses AppArmor
          CAN = lib.mkForce no; # automotive CAN bus
          TARGET_CORE = lib.mkForce no; # network storage target mode
          DM_VDO = lib.mkForce no;
          BLK_DEV_DRBD = lib.mkForce no;
          IP_SCTP = lib.mkForce no;
          TIPC = lib.mkForce no;
          BATMAN_ADV = lib.mkForce no;

          # Intel QuickAssist cryptography accelerators
          CRYPTO_DEV_QAT_4XXX = lib.mkForce no;
          CRYPTO_DEV_QAT_420XX = lib.mkForce no;
          CRYPTO_DEV_QAT_6XXX = lib.mkForce no;
          CRYPTO_DEV_QAT_C3XXX = lib.mkForce no;
          CRYPTO_DEV_QAT_C62X = lib.mkForce no;
          CRYPTO_DEV_QAT_DH895xCC = lib.mkForce no;

          # Exotic and embedded buses. MMC stays because the NixOS initrd needs mmc_block
          MEMSTICK = lib.mkForce no;
          NFC = lib.mkForce no;
          ATM = lib.mkForce no;
          GNSS = lib.mkForce no;
          GPIB = lib.mkForce no;
          GREYBUS = lib.mkForce no;
          MOST = lib.mkForce no;
          RAPIDIO = lib.mkForce no;
          FSI = lib.mkForce no;
          SIOX = lib.mkForce no;
          IPACK_BUS = lib.mkForce no;
          MCB = lib.mkForce no;
          PECI = lib.mkForce no;
          ACCESSIBILITY = lib.mkForce no;
          AUXDISPLAY = lib.mkForce no;
          VDPA = lib.mkForce no;
          NTB = lib.mkForce no;
          CXL_BUS = lib.mkForce no;
          FPGA = lib.mkForce no;
          TEE = lib.mkForce no;
          COUNTER = lib.mkForce no;
          I3C = lib.mkForce no;
          SPMI = lib.mkForce no;
          HSI = lib.mkForce no;
          INTERCONNECT = lib.mkForce no;
          PM_DEVFREQ = lib.mkForce no;
          REMOTEPROC = lib.mkForce no;

          # These need their selectors disabled too, or they get re-enabled
          SOUNDWIRE = lib.mkForce no;
          SOUNDWIRE_QCOM = lib.mkForce no; # selects SLIMBUS
          SLIMBUS = lib.mkForce no;

          RPMSG = lib.mkForce no;
          RPMSG_QCOM_GLINK = lib.mkForce no;
          RPMSG_QCOM_GLINK_RPM = lib.mkForce no; # selects RPMSG_QCOM_GLINK
          RPMSG_VIRTIO = lib.mkForce no;

          LIBNVDIMM = lib.mkForce no;
          ACPI_NFIT = lib.mkForce no; # selects LIBNVDIMM
          X86_PMEM_LEGACY = lib.mkForce no; # selects LIBNVDIMM

          # Device Tree is unused here and takes a lot of embedded drivers with it
          OF = lib.mkForce no;

          # Intel-only x86 code on an AMD machine (PROCESSOR_SELECT must be on for the CPU_SUP_* options to exist)
          PROCESSOR_SELECT = lib.mkForce yes;
          CPU_SUP_AMD = lib.mkForce yes;
          CPU_SUP_INTEL = lib.mkForce no;
          CPU_SUP_HYGON = lib.mkForce no;
          CPU_SUP_CENTAUR = lib.mkForce no;
          CPU_SUP_ZHAOXIN = lib.mkForce no;
          KVM_INTEL = lib.mkForce no; # libvirtd keeps KVM_AMD
          INTEL_IDLE = lib.mkForce no;
          INTEL_IOMMU = lib.mkForce no;
          INTEL_TDX_HOST = lib.mkForce no;
          X86_INTEL_LPSS = lib.mkForce no;
          INTEL_SOC_PMIC = lib.mkForce no;
          HW_RANDOM_INTEL = lib.mkForce no;
          HW_RANDOM_VIA = lib.mkForce no;

          # Intel pinctrl drivers
          PINCTRL_ALDERLAKE = lib.mkForce no;
          PINCTRL_BAYTRAIL = lib.mkForce no;
          PINCTRL_BROXTON = lib.mkForce no;
          PINCTRL_CANNONLAKE = lib.mkForce no;
          PINCTRL_CEDARFORK = lib.mkForce no;
          PINCTRL_CHERRYVIEW = lib.mkForce no;
          PINCTRL_DENVERTON = lib.mkForce no;
          PINCTRL_ELKHARTLAKE = lib.mkForce no;
          PINCTRL_EMMITSBURG = lib.mkForce no;
          PINCTRL_GEMINILAKE = lib.mkForce no;
          PINCTRL_ICELAKE = lib.mkForce no;
          PINCTRL_INTEL_PLATFORM = lib.mkForce no;
          PINCTRL_JASPERLAKE = lib.mkForce no;
          PINCTRL_LAKEFIELD = lib.mkForce no;
          PINCTRL_LEWISBURG = lib.mkForce no;
          PINCTRL_LYNXPOINT = lib.mkForce no;
          PINCTRL_METEORLAKE = lib.mkForce no;
          PINCTRL_METEORPOINT = lib.mkForce no;
          PINCTRL_SUNRISEPOINT = lib.mkForce no;
          PINCTRL_TIGERLAKE = lib.mkForce no;

          # Unused filesystems (ext4, vfat, overlayfs, fuse, btrfs, ntfs3, exfat, iso9660, udf, nfs and cifs are all kept)
          XFS_FS = lib.mkForce no;
          OCFS2_FS = lib.mkForce no;
          GFS2_FS = lib.mkForce no;
          DLM = lib.mkForce no;
          JFS_FS = lib.mkForce no;
          F2FS_FS = lib.mkForce no;
          NILFS2_FS = lib.mkForce no;
          UBIFS_FS = lib.mkForce no;
          JFFS2_FS = lib.mkForce no;
          CEPH_FS = lib.mkForce no;
          ORANGEFS_FS = lib.mkForce no;
          "9P_FS" = lib.mkForce no;
          AFS_FS = lib.mkForce no;
          HFS_FS = lib.mkForce no;
          HFSPLUS_FS = lib.mkForce no;
          MINIX_FS = lib.mkForce no;
          BFS_FS = lib.mkForce no;
          BEFS_FS = lib.mkForce no;
          QNX4FS_FS = lib.mkForce no;
          QNX6FS_FS = lib.mkForce no;
          ROMFS_FS = lib.mkForce no;
          CRAMFS = lib.mkForce no;
          ADFS_FS = lib.mkForce no;
          AFFS_FS = lib.mkForce no;
          HPFS_FS = lib.mkForce no;
          UFS_FS = lib.mkForce no;
          OMFS_FS = lib.mkForce no;
          EFS_FS = lib.mkForce no;
          CODA_FS = lib.mkForce no;
          ZONEFS_FS = lib.mkForce no;
          VBOXSF_FS = lib.mkForce no;
          ECRYPT_FS = lib.mkForce no;
          NTFS_FS = lib.mkForce no; # old read only driver, NTFS3 replaces it

          # Build time savings that do not change behaviour. Only the per module type info is dropped, the main one stays because systemd needs it.
          DEBUG_INFO_BTF_MODULES = lib.mkForce no;
          GDB_SCRIPTS = lib.mkForce no;
          # zstd compresses modules much faster than xz. XZ has to be turned off explicitly or the config generator errors on the conflict.
          MODULE_COMPRESS_XZ = lib.mkForce no;
          MODULE_COMPRESS_ZSTD = lib.mkForce yes;
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
      # XRT_COMPOSITOR_DESIRED_MODE=0 is the 75hz mode XRT_COMPOSITOR_DESIRED_MODE=1 is the 90hz mode
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
