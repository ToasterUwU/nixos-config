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

            workspaces = {
              "01-main" = {
                name = "main";
                open-on-output = "eDP-1";
              };
              "02-social" = {
                name = "social";
                open-on-output = "eDP-1";
              };
            };

            window-rules = [
              {
                matches = [
                  { app-id = "^discord$"; }
                  { app-id = "^sable$"; }
                ];
                open-on-workspace = "social";
                open-focused = false;
              }
            ];
          };
          noctalia-shell = {
            settings = {
              bar = {
                density = "mini";
              };
            };
            pluginSettings = {
              linux-wallpaperengine-controller = {
                screens = {
                  eDP-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/3551537747";
                    scaling = "fill";
                  };
                };
                lastKnownGoodScreens = {
                  eDP-1 = {
                    path = "/home/aki/.local/share/Steam/steamapps/workshop/content/431960/3551537747";
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
