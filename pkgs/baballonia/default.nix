{
  config,
  pkgs,
  lib,
  enableCuda ? config.cudaSupport,
  ...
}:
let
  babbleTrainer = pkgs.callPackage ./babble-trainer.nix { inherit enableCuda; };

  # TODO: figure out how to build & run Godot OpenXR projects.
  calibZip = pkgs.fetchurl {
    url = "https://github.com/Project-Babble/BabbleCalibration/releases/download/1.0.6/Linux.zip";
    hash = "sha256-ytKGg+qVZwHtZUWfJwesvodjIjhffortX6zPs7nWBpU=";
    executable = true;
  };

  opencvsharp = pkgs.stdenv.mkDerivation rec {
    # TODO: figure out how this works on ROCm...

    pname = "opencvsharp";
    version = "4.11.0.20250507";

    src = pkgs.fetchFromGitHub {
      owner = "shimat";
      repo = "opencvsharp";
      tag = version;
      hash = "sha256-CkG4Kx/AkZqyhtclMfS51a9a9R+hsqBRlM4fry32YJ0=";
    };
    sourceRoot = "${src.name}/src";

    patches = [
      ./cvsharp-cv4-compat.patch
    ];

    buildInputs = [ pkgs.opencv ] ++ lib.optionals enableCuda [ pkgs.cudaPackages.cudatoolkit ];

    nativeBuildInputs = [ pkgs.cmake ];

    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    ] ++ lib.optionals enableCuda [ "-DCUDAToolkit_ROOT=${pkgs.cudaPackages.cudatoolkit}" ];
  };
in
pkgs.buildDotnetModule (finalAttrs: {
  # TODO: figure out how this works on ROCm...
  # * Probably a different onnxruntime?
  # * Opencvsharp should just work, I think...
  # * What about babble-trainer?

  version = "0.0.0";
  pname = "baballonia";

  src = pkgs.fetchFromGitHub {
    owner = "Project-Babble";
    repo = "Baballonia";
    rev = "v1.1.0.9rc15";
    hash = "sha256-tI9b4oj0/l98ZdzqDNft369Ij/hGNokyKMxjCNHWAR4=";
    fetchSubmodules = true;
  };
  projectFile = "src/Baballonia.Desktop/Baballonia.Desktop.csproj";
  nugetDeps = ./deps.json;
  dotnetSdk = pkgs.dotnetCorePackages.dotnet_8.sdk;
  dotnetRuntime = pkgs.dotnetCorePackages.dotnet_8.runtime;

  patches = [
    # Remove VCPKG dependancy on "Microsoft.ML.OnnxRuntime" in favor of using the native onnx runtime provided locally
    (pkgs.fetchpatch {
      url = "https://github.com/Project-Babble/Baballonia/commit/1c60dbffab7fa1689d8a441ff52bfd4b0cfecc0c.diff";
      hash = "sha256-k4vTgKgKJg595502TPujEDZIIv6UhZjt23AzPd2IW0s=";
    })
  ];

  buildInputs = with pkgs; [
    cmake
    copyDesktopItems
    fontconfig
    libGL
    libjpeg
    libusb1
    libuvc
    opencv
    opencvsharp
    udev
    unzip
    libICE
    libSM
    libX11
  ];

  runtimeDeps =
    with pkgs;
    [
      libusb1
      libuvc
      libxcb
      libxcursor
      libxext
      libxi
      libxkbcommon
      opencvsharp
      udev
      libGL
      libv4l
    ]
    ++ lib.optionals (!enableCuda) [ onnxruntime ]
    ++ lib.optionals enableCuda [ pkgsCuda.onnxruntime ];

  postUnpack = ''
    unzip ${calibZip} -d $sourceRoot/src/Baballonia.Desktop/Calibration/Linux/Overlay
    ln -s ${babbleTrainer}/bin/babble-trainer $sourceRoot/src/Baballonia.Desktop/Calibration/Linux/Trainer/BabbleTrainer
  '';

  postFixup =
    let
      # The internal calibration tool. We need to wrap this so it launches properly.
      calibTool = "$out/lib/baballonia/Calibration/Linux/Overlay/BabbleCalibration.x86_64";
    in
    ''
      # Clear out bin folder, we'll link since some of these may need
      # to be wrapped. We'll also want to rename them for consistency's
      # sake.
      rm $out/bin/*

      # Ensure BabbleTrainer knows where to put temporary files (NEW!!!)
      wrapDotnetProgram $out/lib/baballonia/Baballonia.Desktop $out/bin/baballonia \
        --set BABBLE_TRAINER_TMP_DIR /tmp

      # Godot applications requires steam-run for whatever reason.
      # I'm too lazy to figure out what part of the FSH it needs.
      # https://nixos.wiki/wiki/Godot
      #
      # Create a backup of the original.
      mv ${calibTool} ${calibTool}-original
      # And wrap it!
      makeWrapper ${pkgs.steam-run}/bin/steam-run \
        ${calibTool} \
        --add-flags ${calibTool}-original \
        --add-flags --xr-mode \
        --add-flags on \
        --set XR_LOADER_DEBUG all

      # Actually export our binaries.
      ln -s ${calibTool} $out/bin/babble-calibration
      ln -s ${babbleTrainer}/bin/babble-trainer $out/bin/babble-trainer

      # Move dll files to Modules that it wants there instead
      mkdir -p $out/lib/baballonia/Modules
      mv $out/lib/baballonia/Baballonia.LibV4L2Capture.dll $out/lib/baballonia/Modules/
      mv $out/lib/baballonia/Baballonia.SerialCameraCapture.dll $out/lib/baballonia/Modules/
      mv $out/lib/baballonia/Baballonia.OpenCVCapture.dll $out/lib/baballonia/Modules/
      mv $out/lib/baballonia/Baballonia.IPCameraCapture.dll $out/lib/baballonia/Modules/
      mv $out/lib/baballonia/Baballonia.VFTCapture.dll $out/lib/baballonia/Modules/
    '';

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "Baballonia";
      comment = finalAttrs.meta.description;
      exec = "${finalAttrs.meta.mainProgram} %u";
      terminal = false;
      type = "Application";
      icon = "baballonia"; # TODO: fetch icon
      categories = [ "Game" ];
    })
  ];

  meta = {
    mainProgram = "baballonia";
    platforms = lib.platforms.linux;
    homepage = "https://github.com/Project-Babble/Baballonia";
    description = "Free and open source eye and face tracking for social VR";
    maintainers = with lib.maintainers; [ naraenda toasteruwu ];
  };
})
