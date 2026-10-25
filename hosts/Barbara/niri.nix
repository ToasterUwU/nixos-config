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

            workspaces = {
              "social" = {
                open-on-output = "HDMI-A-1";
              };
              "TODO" = {
                open-on-output = "DP-2";
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
            bar.main.thickness = 38;
            notification.monitors = [ "DP-3" ];
          };
          noctalia-w-engine.screens = {
            DP-2 = "1463724965";
            DP-3 = "3551537747";
            HDMI-A-1 = "2565816521";
          };
        };
      };
  };
}
