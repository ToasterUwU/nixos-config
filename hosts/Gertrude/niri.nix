{ ... }:
{
  home-manager = {
    users.aki =
      { ... }:
      {
        programs = {
          niri.settings = {
            outputs = {
              "eDP-1" = {
                position = {
                  x = 0;
                  y = 0;
                };
              };
              "HDMI-A-1" = {
                position = {
                  x = 1920;
                  y = 0;
                };
              };
            };
          };
          noctalia-shell = {
            pluginSettings = {
              linux-wallpaperengine-controller = {
                screens = {
                  eDP-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1463724965";
                    scaling = "fill";
                  };
                };
                lastKnownGoodScreens = {
                  eDP-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1463724965";
                    scaling = "fill";
                  };
                };
              };
            };
          };
        };
      };
  };
}