{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  fetchzip,
  replaceVars,
  runtimeShell,
  gradle_8,
  jdk21,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  autoPatchelfHook,
  pkg-config,
  nix-update-script,
  _experimental-update-script-combinators,
  sdl3,
  cairo,
  pango,
  alsa-lib,
  libGL,
  libx11,
  libxcursor,
  libxext,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libxxf86vm,
  udev,
  gtk3,
  xdg-utils,
}:

let
  gradle = gradle_8;
  jdk = jdk21;

  # Loaded at runtime: through JNA (X11 key injection), by the JDK (sound,
  # display, browser), by SDL3 (controllers), and by the natives that the
  # DJL tokenizers and sqlite-jdbc extract to /tmp.
  runtimeLibs = [
    alsa-lib
    gtk3
    libGL
    libx11
    libxcursor
    libxext
    libxi
    libxrandr
    libxrender
    libxtst
    libxxf86vm
    stdenv.cc.cc.lib
    udev
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "elite-intel";
  version = "1.1.0025";

  src = fetchFromGitHub {
    owner = "SudoKrondor";
    repo = "EliteIntel";
    tag = "v-${finalAttrs.version}";
    hash = "sha256-mMK3Bi/TY43bCviU16Qrehhi3IKVwa9k+vX0MF2m6Go=";
  };

  patches = [
    # Load the sherpa-onnx natives installed beside the jar when the jar
    # carries none, instead of requiring bundled prebuilt copies.
    ./patches/load-preinstalled-sherpa-natives.patch
    # -Delite.intel.updates.disabled=true turns off the update check and the
    # self-updater, which would rewrite the (read-only) install directory.
    ./patches/allow-disabling-updater.patch
  ];

  postPatch = ''
    # Prebuilt binaries (or their Git LFS pointers); all built from source here.
    rm -r app/libs app/src/main/resources/native distribution/native distribution/overlays

    substituteInPlace app/build.gradle \
      --replace-fail "files('libs/sherpa-onnx-v1.13.8.jar')" \
                     "files('${finalAttrs.passthru.sherpa-onnx-java}/share/java/sherpa-onnx.jar')" \
      --replace-fail "'com.microsoft.onnxruntime:onnxruntime:1.20.0'" \
                     "files('${finalAttrs.passthru.onnxruntime-java}/share/java/onnxruntime.jar')" \
      --replace-fail "include '**/native/**/*.so'" "" \
      --replace-fail "include '**/native/**/*.dll'" ""

    # The Sonatype snapshots repository is gone and nothing needs it.
    sed -i '/maven {/{N;N;/oss\.sonatype\.org/d}' build.gradle app/build.gradle
    if grep -q oss.sonatype.org build.gradle app/build.gradle; then
      echo "failed to remove the Sonatype repository" >&2
      exit 1
    fi

    # Tuned for upstream's workstation (6 GB daemon heap, configuration cache).
    cat > gradle.properties <<EOF
    org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
    EOF
  '';

  nativeBuildInputs = [
    gradle
    makeWrapper
    copyDesktopItems
    autoPatchelfHook
    pkg-config
  ];

  buildInputs = [
    # For the LWJGL native extracted from its Maven jar.
    stdenv.cc.cc.lib
    # For the HUD overlay.
    cairo
    libx11
    libxrandr
    pango
  ];

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  gradleFlags = [
    "-Dfile.encoding=utf-8"
    "-Dorg.gradle.java.home=${jdk}"
    "-Porg.gradle.java.installations.auto-download=false"
  ];

  gradleBuildTask = ":app:shadowJar";

  # The native HUD overlay; upstream commits a prebuilt binary instead.
  postBuild = ''
    make -C overlay OUT_DIR=build
  '';

  installPhase = ''
    runHook preInstall

    # EliteIntel looks for everything else relative to its jar.
    app=$out/share/elite-intel
    install -Dm644 distribution/elite_intel.jar -t $app

    # Models: replace the LFS pointers in the source with the pinned files.
    cp -r distribution/{tts,parakeet,embed} $app/
    lfsOid() {
      sed -n 's/^oid sha256://p' "$1"
    }
    ${lib.concatStrings (
      lib.mapAttrsToList (path: pin: ''
        if [ "$(lfsOid $app/${path})" != ${pin.oid} ]; then
          echo "${path} changed upstream; update its pin in models.nix" >&2
          exit 1
        fi
        ln -sf ${pin.file} $app/${path}
      '') finalAttrs.passthru.models.files
    )}
    espeak=$app/tts/kokoro-multi-lang-v1_0/espeak-ng-data
    espeakPinned=${finalAttrs.passthru.models.kokoroEspeakNgData}/espeak-ng-data
    while IFS= read -r -d "" pointer; do
      oid=$(lfsOid "$pointer")
      actual=$(sha256sum < "$espeakPinned/''${pointer#$espeak/}")
      if [ -z "$oid" ] || [ "$oid  -" != "$actual" ]; then
        echo "''${pointer#$app/} changed upstream; update models.nix" >&2
        exit 1
      fi
    done < <(find $espeak -type f -print0)
    rm -r $espeak
    ln -s $espeakPinned $espeak
    if grep -rl '^version https://git-lfs.github.com/spec' $app; then
      echo "the files above are LFS pointers without a pin in models.nix" >&2
      exit 1
    fi

    # The JNI library finds ONNX Runtime through its runpath.
    mkdir -p $app/native/sherpa-onnx $app/native/lwjgl $app/overlays
    ln -s ${finalAttrs.passthru.sherpa-onnx-java}/lib/libsherpa-onnx-jni.so $app/native/sherpa-onnx/
    install -Dm755 distribution/native/lwjgl/liblwjgl.so -t $app/native/lwjgl
    ln -s ${lib.getLib sdl3}/lib/libSDL3.so $app/native/lwjgl/
    install -Dm755 overlay/build/elite-intel-overlay -t $app/overlays

    install -Dm644 app/src/main/resources/images/elite-icon.png \
      $out/share/icons/hicolor/256x256/apps/elite-intel.png

    install -Dm755 ${
      replaceVars ./launcher.sh {
        inherit runtimeShell;
        java = lib.getExe jdk;
        javaFlags = lib.concatStringsSep " " [
          "-Xmx6g"
          "-Delite.intel.updates.disabled=true"
          "-Donnxruntime.native.path=${finalAttrs.passthru.onnxruntime-java}/lib"
        ];
        # Substituted below; placeholder "out" here would be replaceVars' own.
        jar = null;
      }
    } $out/bin/elite-intel
    substituteInPlace $out/bin/elite-intel --subst-var-by jar $app/elite_intel.jar
    wrapProgram $out/bin/elite-intel \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --set-default _JAVA_AWT_WM_NONREPARENTING 1

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "elite-intel";
      exec = "elite-intel";
      icon = "elite-intel";
      desktopName = "Elite Intel";
      comment = "Elite Dangerous AI companion";
      categories = [
        "Game"
        "Utility"
      ];
    })
  ];

  passthru = {
    sherpa-onnx-java = callPackage ./sherpa-onnx-java.nix { };
    onnxruntime-java = callPackage ./onnxruntime-java.nix { };
    models = import ./models.nix {
      inherit fetchurl fetchzip;
      inherit (finalAttrs) src;
    };

    updateScript = _experimental-update-script-combinators.sequence [
      (nix-update-script {
        extraArgs = [
          "--version-regex"
          "^v-(\\d+\\.\\d+\\.\\d+)$"
        ];
      })
      finalAttrs.mitmCache.updateScript
    ];
  };

  meta = {
    description = "Voice-driven AI companion for Elite Dangerous";
    homepage = "https://github.com/SudoKrondor/EliteIntel";
    changelog = "https://github.com/SudoKrondor/EliteIntel/releases/tag/${finalAttrs.src.tag}";
    license = with lib.licenses; [
      cc0
      # Bundled dependencies, see THIRD_PARTY_NOTICES.md
      lgpl21Plus
      asl20
      # Models
      cc-by-40 # parakeet-tdt-0.6b-v3
      mit # supertonic-3, multilingual-e5-small; kokoro is asl20
    ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # Maven dependencies
      binaryNativeCode # natives inside Maven jars (LWJGL, DJL tokenizers, sqlite-jdbc, JNA)
    ];
    maintainers = with lib.maintainers; [ toasteruwu ];
    mainProgram = "elite-intel";
    platforms = [ "x86_64-linux" ];
  };
})
