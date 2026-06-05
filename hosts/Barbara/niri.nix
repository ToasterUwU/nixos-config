{ ... }:
{
  home-manager = {
    users.aki =
      { ... }:
      {
        programs = {
          niri.settings = {
            outputs = {
              "DP-2" = {
                position = {
                  x = 0;
                  y = 0;
                };
              };
              "DP-3" = {
                position = {
                  x = 2560;
                  y = 0;
                };
                variable-refresh-rate = true;
              };
              "HDMI-A-1" = {
                position = {
                  x = 5120;
                  y = 0;
                };
              };
            };
          };
          noctalia-shell = {
            settings = {
              bar = {
                density = "comfortable";
              };
            };
            pluginSettings = {
              linux-wallpaperengine-controller = {
                screens = {
                  DP-2 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1463724965";
                    scaling = "fill";
                  };
                  DP-3 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/3551537747";
                    scaling = "fill";
                  };
                  HDMI-A-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/2565816521";
                    scaling = "fill";
                  };
                };
                lastKnownGoodScreens = {
                  DP-2 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1463724965";
                    scaling = "fill";
                  };
                  DP-3 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/3551537747";
                    scaling = "fill";
                  };
                  HDMI-A-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/2565816521";
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
