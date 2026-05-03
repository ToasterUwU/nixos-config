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
            pluginSettings = {
              linux-wallpaperengine-controller = {
                screens = {
                  HDMI-A-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/820705596";
                    scaling = "fill";
                  };
                  DP-3 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1463724965";
                    scaling = "fill";
                  };
                  DP-2 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1498288260";
                    scaling = "fill";
                  };
                };
                lastKnownGoodScreens = {
                  HDMI-A-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/820705596";
                    scaling = "fill";
                  };
                  DP-3 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1463724965";
                    scaling = "fill";
                  };
                  DP-2 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/1498288260";
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