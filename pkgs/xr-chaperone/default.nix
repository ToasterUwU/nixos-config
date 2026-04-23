{
  rustPlatform,
  fetchFromGitHub,
  cmake,
  git,
  python3,
  openxr-loader,
  libxkbcommon,
  lib
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xr-chaperone";
  version = "bb3a78dc8abc802f51b4a257a019b31e0e03c940";

  src = fetchFromGitHub {
    owner = "FrostyCoolSlug";
    repo = "xr-chaperone";
    rev = finalAttrs.version;
    hash = "sha256-djMOvA1XIYlQgXxBNEbCbSdHAMOmyUGTVqeIEV8Nv3c=";
  };

  cargoHash = "sha256-9uEosKwKGNruwxp/uslXj0WAFowY4Tu2CikWa2JiOf4=";

  nativeBuildInputs = [
    cmake
    git
    python3
  ];

  buildInputs = [
    openxr-loader
  ];

  postInstall = ''
    patchelf $out/bin/xr-chaperone \
      --add-needed ${lib.getLib libxkbcommon}/lib/libxkbcommon.so.0
  '';

  meta = {
    description = "VR Chaperone System for OpenXR ";
    homepage = "https://github.com/FrostyCoolSlug/xr-chaperone";
    mainProgram = "xr-chaperone";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ toasteruwu ];
  };
})
