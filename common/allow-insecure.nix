{ ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];
}
