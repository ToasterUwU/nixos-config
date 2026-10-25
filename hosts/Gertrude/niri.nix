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
              "03-TODO" = {
                name = "TODO";
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
              {
                matches = [ { app-id = "^superproductivity$"; } ];
                open-on-workspace = "TODO";
                open-focused = false;
                open-maximized = true;
              }
            ];
          };
          noctalia.settings = {
            bar.main = {
              thickness = 26;
              scale = 0.85;
            };
          };
          noctalia-w-engine.screens = {
            eDP-1 = "3551537747";
          };
        };
      };
  };
}
