{ ... }:
{
  specialisation = {
    gramps-mode-cinnamon = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./gramps-mode/gramps-configuration.nix
          ../../common/allow-unfree-software.nix
        ];

        services.xserver.desktopManager.cinnamon.enable = true;
        services.xserver.displayManager.lightdm.enable = true;
        services.xserver.enable = true;
      };
    };
    gramps-mode-xfce = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./gramps-mode/gramps-configuration.nix
          ../../common/allow-unfree-software.nix
        ];

        services.xserver = {
          enable = true;
          desktopManager = {
            xterm.enable = false;
            xfce.enable = true;
          };
        };
        services.displayManager.defaultSession = "xfce";
      };
    };
    gramps-mode-kde = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./gramps-mode/gramps-configuration.nix
          ../../common/allow-unfree-software.nix
        ];

        services.desktopManager.plasma6.enable = true;
        services.displayManager.plasma-login-manager = {
          enable = true;
        };

        programs = {
          chromium.enablePlasmaBrowserIntegration = true;
        };
      };
    };
    gramps-mode-lxqt = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./gramps-mode/gramps-configuration.nix
          ../../common/allow-unfree-software.nix
        ];

        services.xserver.desktopManager.lxqt.enable = true;
        services.xserver.displayManager.lightdm.enable = true;
        services.xserver.enable = true;
      };
    };
    gramps-mode-budgie = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./gramps-mode/gramps-configuration.nix
          ../../common/allow-unfree-software.nix
        ];

        services.xserver.desktopManager.budgie.enable = true;
        services.xserver.displayManager.lightdm.enable = true;
        services.xserver.enable = true;
      };
    };
    gramps-mode-gnome = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./gramps-mode/gramps-configuration.nix
          ../../common/allow-unfree-software.nix
        ];

        services.xserver.desktopManager.gnome.enable = true;
        services.displayManager.gdm.enable = true;
      };
    };
  };
}
