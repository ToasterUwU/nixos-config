{
  rustPlatform,
  fetchgit,
  lib,
  stdenv,
  fetchNpmDeps,
  autoPatchelfHook,
  cargo-tauri,
  nodejs,
  npmHooks,
  pkg-config,
  wrapGAppsHook4,
  webkitgtk_4_1,
  gtk3,
  dbus,
  gst_all_1,
  glib,
  glib-networking,
  libappindicator,
  librsvg,
  openssl,
  libsoup_3,
}:
let
  gtk = gtk3;
  libsoup = libsoup_3;
  webkitgtk = webkitgtk_4_1;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cyberia";
  version = "0.2.1-2";

  src = fetchgit {
    url = "https://git.gay/zutyosh/Cyberia.git";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Rmd/B3oDcH2R+p+WSO8QGOsDsNO0Jp/FLJf83dhOdcw=";
  };

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;
  cargoHash = "sha256-n7Om0JQVC1wwaUhSNEki5kbPa1lazbk5MEuwUzTf1jE=";

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    hash = "sha256-G9SB643obh0xCOXu2baHLi8aVOIX3dapSq6M4Lo0Ez4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook

    cargo-tauri.hook

    nodejs
    npmHooks.npmConfigHook

    pkg-config
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = (
    lib.optionals stdenv.hostPlatform.isLinux [
      dbus
      glib
      glib-networking
      gtk
      libappindicator
      librsvg
      libsoup
      openssl
      webkitgtk
    ]
    ++ (with gst_all_1; [
      gst-plugins-bad # fakevideosink
      gst-plugins-base # appsink and autoaudiosink
      gst-plugins-good # autoaudiosink
    ])
  );

  meta = {
    description = "VRCX style client for Resonite";
    homepage = "https://git.gay/zutyosh/Cyberia";
    changelog = "https://git.gay/zutyosh/Cyberia/releases/tag/v${finalAttrs.version}";
    maintainers = with lib.maintainers; [ toasteruwu ];
    license = lib.licenses.unlicense;
    mainProgram = "cyberia";
  };
})
