{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024; # x GB * 1024
    }
  ];

  networking.hostName = "Barbara";
  networking.interfaces.enp16s0.wakeOnLan.enable = true;

  networking.firewall.enable = false;
}
