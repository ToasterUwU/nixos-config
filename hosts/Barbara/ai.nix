{ pkgs, lmstudio, ... }:
{
  nixpkgs.overlays = [ lmstudio.overlays.default ];

  environment.systemPackages = [ pkgs.lmstudio ];
}
