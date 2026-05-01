{ pkgs, ... }:
{
  extract-audio = pkgs.callPackage ./extract-audio { };
  split-3d-image = pkgs.callPackage ./split-3d-image { };
  monado-start = pkgs.callPackage ./monado-start { };
}
