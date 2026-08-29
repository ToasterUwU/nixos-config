{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Gertrude";

  system.autoUpgrade = {
    flags = [
      "--build-host 192.168.178.100"
    ];
  };
}
