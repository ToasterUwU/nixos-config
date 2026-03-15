{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libreoffice
    hunspell
    hunspellDicts.de_DE
    hunspellDicts.en_US
  ];
}
