{ ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
    "python3.14-python-jose-3.5.0" # needed by pyfa
  ];
}
