{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  bun,
  cargo-tauri,
  glib-networking,
  libayatana-appindicator,
  nix-update-script,
  nodejs,
  openssl,
  pkg-config,
  webkitgtk_4_1,
  wrapGAppsHook4,
  writableTmpDirAsHomeHook,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "deezy";
  version = "0.2.22";

  src = fetchFromGitHub {
    owner = "PierrunoYT";
    repo = "Deezy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-2KA9wwORNltbkM2bVaHmQR/JFSOro//MLUCAMEorhQg=";
  };

  # Upstream does not commit a Cargo.lock, so we keep one next to this file.
  cargoLock.lockFile = ./Cargo.lock;

  cargoRoot = "deezy/src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  # Upstream uses bun, for which nixpkgs has no dependency fetcher or hook yet,
  # so node_modules is produced by a fixed-output derivation. bun resolves
  # platform-specific optional dependencies (esbuild, rollup), which is why the
  # hash differs per system.
  nodeModules = stdenv.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;
    dontFixup = true;
    # Shebangs are patched in the main derivation, after node_modules is copied in.
    dontPatchShebangs = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      cd deezy
      bun install \
        --force \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -R node_modules $out

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash =
      {
        x86_64-linux = "sha256-LkNaNIUk+kO7OMLCmIttL0xL+l7W2RlNY+3WFVThxUQ=";
      }
      .${stdenv.hostPlatform.system} or (throw "Unsupported system ${stdenv.hostPlatform.system}");
  };

  postPatch = ''
    cp ${./Cargo.lock} deezy/src-tauri/Cargo.lock

    substituteInPlace deezy/src-tauri/tauri.conf.json \
      --replace-fail '"npm run build"' '"bun run build"'

    cp -R ${finalAttrs.nodeModules} deezy/node_modules
    chmod -R u+w deezy/node_modules
    patchShebangs deezy/node_modules

    # The tray icon is loaded via dlopen at runtime, so point it at the store.
    substituteInPlace "$cargoDepsCopy"/libappindicator-sys-*/src/lib.rs \
      --replace-fail 'libayatana-appindicator3.so.1' \
        '${libayatana-appindicator}/lib/libayatana-appindicator3.so.1'
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    bun
    nodejs
    pkg-config
    writableTmpDirAsHomeHook
    wrapGAppsHook4
  ];

  buildInputs = [
    glib-networking
    libayatana-appindicator
    openssl
    webkitgtk_4_1
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Modern desktop Deezer downloader";
    longDescription = ''
      Search for tracks, albums, and artists, queue downloads, and save them as
      high-quality MP3 or FLAC with full metadata and cover art.
    '';
    homepage = "https://github.com/PierrunoYT/Deezy";
    changelog = "https://github.com/PierrunoYT/Deezy/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ toasteruwu ];
    mainProgram = "deezy";
    # Only x86_64-linux is packaged: node_modules is a fixed-output derivation
    # whose hash is platform-specific and has not been generated elsewhere.
    platforms = [ "x86_64-linux" ];
  };
})
