{
  lib,
  pkgs,
  config,
  niri,
  walker,
  ...
}:
{
  nixpkgs.overlays = [
    niri.overlays.niri
    (final: prev: {
      wpaperd = prev.wpaperd.overrideAttrs rec {
        version = "master";

        src = pkgs.fetchFromGitHub {
          owner = "danyspin97";
          repo = "wpaperd";
          rev = "7a0fbc954a3009f522e664ce7a6f261ecbf1b172";
          hash = "sha256-WByb493PT3RcH9RH/VQTabjQUC1jgXO12ZXMSZgoS0M=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-Vz5x9V+q5OwRR/GdiM/kEEfENSQ+KyN3DKM35NHuzAk=";
        };
      };
    })
  ];

  nix.settings = {
    extra-substituters = [
      "https://walker.cachix.org"
      "https://walker-git.cachix.org"
    ];
    extra-trusted-public-keys = [
      "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
    ];
  };

  # Higher ulimit as fix for https://github.com/YaLTeR/niri/issues/2377
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "8192";
    }
  ];

  services.greetd = {
    enable = true;
    restart = true;
    settings = {
      default_session = {
        command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-user-session --user-menu --cmd niri-session";
      };
    };
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };
  programs.waybar = {
    enable = true;
  };

  programs.kdeconnect.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Access" = "gtk";
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
      "org.freedesktop.impl.portal.Notification" = "gtk";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
  };

  # Needed for iwmenu
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Needed for Nemo Networking
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    config.services.greetd.package

    xwayland-satellite

    nemo-with-extensions
    xviewer
    pavucontrol

    pwmenu
    iwmenu
    bzmenu

    catppuccin-cursors.mochaPink
  ];

  home-manager = {
    users.aki =
      { config, ... }:
      {
        imports = [ walker.homeManagerModules.default ];

        xdg.desktopEntries.nemo = {
          name = "Nemo";
          exec = "${pkgs.nemo-with-extensions}/bin/nemo";
        };
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "inode/directory" = [ "nemo.desktop" ];
            "application/x-gnome-saved-search" = [ "nemo.desktop" ];
            "image/jpeg" = [ "xviewer.desktop" ];
            "image/png" = [ "xviewer.desktop" ];
          };
        };
        dconf = {
          settings = {
            "org/cinnamon/desktop/applications/terminal" = {
              exec = "alacritty";
            };
            "org/cinnamon/desktop/interface" = {
              can-change-accels = true;
            };
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
            };
          };
        };
        home.file = {
          ".gnome2/accels/nemo".text = ''
            (gtk_accel_path "<Actions>/DirViewActions/OpenInTerminal" "F4")
          '';
        };

        services = {
          mako = {
            enable = true;
            settings = {
              default-timeout = 30000;
            };
            # Dont ever remove notifications that are important
            extraConfig = ''
              [urgency="critical"]
              default-timeout=0
            '';
          };
          swayidle.enable = true;
          wpaperd = {
            enable = true;
            settings = {
              default = {
                duration = "10m";
                sorting = "random";
                mode = "center";
                path = ../assets/wallpapers;
              };
            };
          };
        };

        xdg.configFile."elephant/websearch.toml".text = ''
          [[entries]]
          default = true
          name = "DuckDuckGo"
          url = "https://duckduckgo.com/?q=%TERM%"
        '';

        xdg.configFile."waybar/mocha.css".source = ../assets/waybar/mocha.css;

        programs = {
          swaylock.enable = true;
          alacritty = {
            enable = true;
            settings = {
              window.decorations = "None";
              font.normal = {
                family = "FiraCode Nerd Font Mono";
                style = "Regular";
              };
            };
          };
          walker = {
            enable = true;
            runAsService = true;

            # All options from the config.toml can be used here https://github.com/abenz1267/walker/blob/master/resources/config.toml
            config = {
              theme = "mocha";
              force_keyboard_focus = true;
              placeholders."default" = {
                input = "Search";
                list = "Empty List";
              };
              providers = {
                default = [
                  "desktopapplications"
                  "calc"
                ];
                prefixes = [
                  {
                    provider = "providerlist";
                    prefix = ";";
                  }
                  {
                    provider = "clipboard";
                    prefix = ":";
                  }
                  {
                    provider = "calc";
                    prefix = "=";
                  }
                  {
                    provider = "files";
                    prefix = "/";
                  }
                  {
                    provider = "runner";
                    prefix = ">";
                  }
                ];
              };
              keybinds.quick_activate = [
                "F1"
                "F2"
                "F3"
                "F4"
              ];
            };

            themes = {
              "mocha" = {
                style = ''
                  @define-color window_bg_color #1e1e2e;
                  @define-color accent_bg_color #f5c2e7;
                  @define-color theme_fg_color #f5c2e7;
                  @define-color error_bg_color #1e1e2e;
                  @define-color error_fg_color #f38ba8;
                '';
              };
            };
          };
          waybar = {
            enable = true;
            systemd.enable = true;
            settings = {
              mainBar = {
                layer = "top";
                position = "top";
                height = 35;
                modules-left = [ "niri/workspaces" ];
                modules-center = [ "niri/window" ];
                modules-right = [
                  "group/hardware"
                  "battery"
                  "backlight"
                  "bluetooth"
                  "wireplumber#sink"
                  "network"
                  "tray"
                  "clock"
                  "group/session"
                ];
                "niri/window" = {
                  format = "<span color='#F5C2E7'>{title}</span>";
                  rewrite = {
                    "" = "Niri";
                  };
                };
                "niri/workspaces" = {
                  format = "{icon}";
                  on-click = "activate";
                  format-icons = {
                    "default" = "";
                    "1" = "1";
                    "2" = "2";
                    "3" = "3";
                    "4" = "4";
                    "5" = "5";
                    "6" = "6";
                    "7" = "7";
                    "8" = "8";
                    "9" = "9";
                    "active" = "";
                  };
                  persistent-workspaces = {
                    "1" = [ ];
                    "2" = [ ];
                    "3" = [ ];
                    "4" = [ ];
                    "5" = [ ];
                  };
                };
                "clock" = {
                  format = "󰥔 {:%H:%M}";
                  format-alt = "󰥔 {:%H:%M 󰃮 %B %d, %Y}";
                  tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
                  calendar = {
                    mode = "month";
                    mode-mon-col = 3;
                    weeks-pos = "right";
                    on-scroll = 1;
                    on-click-right = "mode";
                  };
                  actions = {
                    on-click-right = "mode";
                    on-click-forward = "tz_up";
                    on-click-backward = "tz_down";
                    on-scroll-up = "shift_up";
                    on-scroll-down = "shift_down";
                  };
                };
                "custom/hardware-wrap" = {
                  format = "<big></big>";
                  tooltip-format = "Resource Usage";
                };
                "group/hardware" = {
                  orientation = "horizontal";
                  drawer = {
                    "transition-duration" = 500;
                    "transition-left-to-right" = true;
                  };
                  modules = [
                    "custom/hardware-wrap"
                    "power-profiles-daemon"
                    "cpu"
                    "memory"
                    "temperature"
                    "disk"
                  ];
                };
                "cpu" = {
                  format = "󰘚 {usage}%";
                  tooltip = true;
                  interval = 1;
                  on-click = "${lib.getExe pkgs.alacritty} -e ${lib.getExe pkgs.bottom}";
                };
                "memory" = {
                  format = "󰍛 {}%";
                  interval = 1;
                  on-click = "${lib.getExe pkgs.alacritty} -e ${lib.getExe pkgs.bottom}";
                };
                "temperature" = {
                  critical-threshold = 90;
                  format = "{icon} {temperatureC}°C";
                  format-icons = [
                    "󱃃"
                    "󰔏"
                    "󱃂"
                  ];
                  on-click = "${lib.getExe pkgs.alacritty} -e ${lib.getExe pkgs.bottom}";
                };
                "battery" = {
                  format = "{icon}";
                  format-full = "{icon}";
                  format-charging = "󰂄";
                  format-plugged = "";
                  format-icons = [
                    ""
                    ""
                    ""
                    ""
                    ""
                  ];
                  tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
                  tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
                  interval = 5;
                  states = {
                    warning = 20;
                    critical = 10;
                  };
                };
                "network" = {
                  format-wifi = "󰖩 {essid} ({signalStrength}%)";
                  format-ethernet = "󰈀 {ifname}";
                  format-linked = "󰈀 {ifname} (No IP)";
                  format-disconnected = "󰖪 Disconnected";
                  format-alt = "{ifname}: {ipaddr}/{cidr}";
                  tooltip-format = "{ifname}: {ipaddr}";
                };
                "bluetooth" = {
                  format = " {status}";
                  format-connected = " {device_alias}";
                  format-connected-battery = " {device_alias} {device_battery_percentage}%";
                };
                "wireplumber#sink" = {
                  format = "<big>{icon}</big> {volume}%";
                  format-muted = "";
                  format-icons = [
                    ""
                    ""
                    ""
                  ];
                  on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                  on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 1%-";
                  on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 1%+";
                };
                "backlight" = {
                  format = "{icon} {percent}%";
                  format-icons = [
                    "󰃞"
                    "󰃟"
                    "󰃠"
                  ];
                  on-scroll-up = "${lib.getExe pkgs.brightnessctl} set +5%";
                  on-scroll-down = "${lib.getExe pkgs.brightnessctl} set -5%";
                };
                "disk" = {
                  interval = 30;
                  format = "󰋊 {percentage_used}%";
                  path = "/";
                  on-click = "${lib.getExe pkgs.alacritty} -e ${lib.getExe pkgs.bottom}";
                };
                "tray" = {
                  icon-size = 16;
                  spacing = 5;
                };
                "power-profiles-daemon" = {
                  format = "{icon}";
                  tooltip-format = "Power profile: {profile}\nDriver: {driver}";
                  tooltip = true;
                  format-icons = {
                    default = "";
                    performance = "";
                    balanced = "";
                    power-saver = "";
                  };
                };
                "group/session" = {
                  orientation = "horizontal";
                  drawer = {
                    "transition-duration" = 500;
                    "transition-left-to-right" = true;
                  };
                  modules = [
                    "custom/session-wrap"
                    "custom/lock"
                    "custom/reboot"
                    "custom/power"
                  ];
                };
                "custom/session-wrap" = {
                  format = "  ";
                  tooltip-format = "Lock, Reboot, Shutdown";
                };
                "custom/lock" = {
                  format = "  ";
                  on-click = "${lib.getExe pkgs.swaylock}";
                  tooltip = true;
                  tooltip-format = "Lock screen";
                };
                "custom/reboot" = {
                  format = "  ";
                  on-click = "${pkgs.systemd}/bin/systemctl reboot";
                  tooltip = true;
                  tooltip-format = "Reboot";
                };
                "custom/power" = {
                  format = "  ";
                  on-click = "${pkgs.systemd}/bin/systemctl poweroff";
                  tooltip = true;
                  tooltip-format = "Shutdown";
                };
              };
            };
            style = ''
              @import "mocha.css";

              * {
                font-family: "FiraCode Nerd Font Mono";
                font-size: 14px;
              }

              window#waybar {
                background-color: @base;
                border-radius: 0px;
                transition-property: background-color;
                transition-duration: 0.5s;
              }

              button {
                /* Use box-shadow instead of border so the text isn't offset */
                box-shadow: inset 0 -3px transparent;
                /* Avoid rounded borders under each button name */
                border: none;
                border-radius: 0;
              }

              /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
              button:hover {
                background: inherit;
                box-shadow: inset 0 -3px #ffffff;
              }

              #workspaces button {
                padding: 0 5px;
                background-color: transparent;
                color: #ffffff;
              }

              #workspaces button:hover {
                background: rgba(0, 0, 0, 0.2);
              }

              #workspaces button.focused {
                background-color: @pink;
                box-shadow: inset 0 -3px #ffffff;
              }

              #workspaces button.urgent {
                background-color: #eb4d4b;
              }

              #mode {
                background-color: #64727d;
                box-shadow: inset 0 -3px #ffffff;
              }

              #clock,
              #battery,
              #cpu,
              #disk,
              #power-profile-daemon,
              #wireplumber,
              #backlight,
              #tray,
              #memory,
              #temperature,
              #network,
              #bluetooth,
              #custom {
                padding: 0 10px;
              }

              #wireplumber {
                color: @maroon;
              }

              #network {
                color: @yellow;
              }

              #battery {
                color: @green;
              }

              #clock {
                color: @flamingo;
              }

              #window {
                color: @text;
              }

              #bluetooth {
                color: @blue;
              }

              #custom-wlogout {
                color: @mauve;
              }

              .modules-right,
              .modules-left,
              .modules-center {
                background-color: @base;
                border-radius: 0px;
              }
              .modules-right {
                padding: 0 0px;
              }

              .modules-left {
                padding: 0 0px;
              }

              .modules-center {
                padding: 0 10px;
              }
              #battery.charging,
              #battery.plugged {
                color: @sapphire;
              }

              @keyframes blink {
                to {
                  color: #000000;
                }
              }

              /* Using steps() instead of linear as a timing function to limit cpu usage */
              #battery.critical:not(.charging) {
                background-color: #f53c3c;
                color: #ffffff;
                animation-name: blink;
                animation-duration: 0.5s;
                animation-timing-function: steps(12);
                animation-iteration-count: infinite;
                animation-direction: alternate;
              }

              label:focus {
                background-color: #000000;
              }

              #tray>.passive {
                  -gtk-icon-effect: dim;
              }

              #tray>.needs-attention {
                  -gtk-icon-effect: highlight;
                  color: @red;
                  border-bottom-color: @red;
              }
            '';
          };
          niri.settings = {
            environment."NIXOS_OZONE_WL" = "1";
            xwayland-satellite.enable = true;

            prefer-no-csd = true;

            hotkey-overlay.skip-at-startup = true;
            gestures.hot-corners.enable = false;

            cursor = {
              theme = "catppuccin-mocha-pink-cursors";
              size = 24;
            };

            input = {
              keyboard = {
                xkb = {
                  layout = "de";
                };
                numlock = true;
              };

              touchpad = {
                tap = true;
                natural-scroll = false;
                disabled-on-external-mouse = false;
              };

              mouse = {
                accel-profile = "flat";
              };

              warp-mouse-to-focus.enable = true;

              focus-follows-mouse = {
                max-scroll-amount = "0%";
              };
            };

            layout = {
              gaps = 8;

              center-focused-column = "never";

              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];

              default-column-width = {
                proportion = 0.5;
              };

              focus-ring = {
                width = 4;

                active = {
                  color = "#f5c2e7";
                };

                inactive = {
                  color = "#505050";
                };
              };

              border = {
                enable = false;

                width = 4;
                active = {
                  color = "#ffc87f";
                };
                inactive = {
                  color = "#505050";
                };

                urgent = {
                  color = "#9b0000";
                };
              };
            };

            screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

            # https://github.com/YaLTeR/niri/wiki/Configuration:-Animations
            animations = {
              enable = true;
            };

            binds =
              with config.lib.niri.actions;
              let
                playerctl = spawn "${pkgs.playerctl}/bin/playerctl";
                wpctl = spawn "${pkgs.wireplumber}/bin/wpctl";
              in
              {
                "Mod+Shift+Slash".action = show-hotkey-overlay;
                "Mod+T" = {
                  hotkey-overlay.title = "Open a Terminal: alacritty";
                  action = spawn "${lib.getExe pkgs.alacritty}";
                };
                "Mod+D" = {
                  hotkey-overlay.title = "Run an Application: walker";
                  action = spawn "${lib.getExe pkgs.walker}";
                };
                "Super+Alt+L" = {
                  hotkey-overlay.title = "Lock the Screen: swaylock";
                  action = spawn "${lib.getExe pkgs.swaylock}";
                };

                "XF86AudioMute".action = wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
                "XF86AudioMicMute".action = wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
                "XF86AudioRaiseVolume".action = wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
                "XF86AudioLowerVolume".action = wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";

                "XF86AudioPlay".action = playerctl "play-pause";
                "XF86AudioStop".action = playerctl "pause";
                "XF86AudioPrev".action = playerctl "previous";
                "XF86AudioNext".action = playerctl "next";

                "XF86MonBrightnessUp".action = spawn "${lib.getExe pkgs.brightnessctl} set +5%";
                "XF86MonBrightnessDown".action = spawn "${lib.getExe pkgs.brightnessctl} set -5%";

                "Mod+O" = {
                  repeat = false;
                  action = toggle-overview;
                };

                "Mod+Q".action = close-window;

                "Mod+Left".action = focus-column-left;
                "Mod+Down".action = focus-window-down;
                "Mod+Up".action = focus-window-up;
                "Mod+Right".action = focus-column-right;
                "Mod+H".action = focus-column-left;
                "Mod+J".action = focus-window-down;
                "Mod+K".action = focus-window-up;
                "Mod+L".action = focus-column-right;

                "Mod+Ctrl+Left".action = move-column-left;
                "Mod+Ctrl+Down".action = move-window-down;
                "Mod+Ctrl+Up".action = move-window-up;
                "Mod+Ctrl+Right".action = move-column-right;
                "Mod+Ctrl+H".action = move-column-left;
                "Mod+Ctrl+J".action = move-window-down;
                "Mod+Ctrl+K".action = move-window-up;
                "Mod+Ctrl+L".action = move-column-right;

                "Mod+Home".action = focus-column-first;
                "Mod+End".action = focus-column-last;
                "Mod+Ctrl+Home".action = move-column-to-first;
                "Mod+Ctrl+End".action = move-column-to-last;

                "Mod+Shift+Left".action = focus-monitor-left;
                "Mod+Shift+Down".action = focus-monitor-down;
                "Mod+Shift+Up".action = focus-monitor-up;
                "Mod+Shift+Right".action = focus-monitor-right;
                "Mod+Shift+H".action = focus-monitor-left;
                "Mod+Shift+J".action = focus-monitor-down;
                "Mod+Shift+K".action = focus-monitor-up;
                "Mod+Shift+L".action = focus-monitor-right;

                "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
                "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
                "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
                "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
                "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
                "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
                "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
                "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

                "Mod+Page_Down".action = focus-workspace-down;
                "Mod+Page_Up".action = focus-workspace-up;
                "Mod+U".action = focus-workspace-down;
                "Mod+I".action = focus-workspace-up;
                "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
                "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
                "Mod+Ctrl+U".action = move-column-to-workspace-down;
                "Mod+Ctrl+I".action = move-column-to-workspace-up;

                "Mod+Shift+Page_Down".action = move-workspace-down;
                "Mod+Shift+Page_Up".action = move-workspace-up;
                "Mod+Shift+U".action = move-workspace-down;
                "Mod+Shift+I".action = move-workspace-up;

                "Mod+WheelScrollDown" = {
                  cooldown-ms = 150;
                  action = focus-workspace-down;
                };
                "Mod+WheelScrollUp" = {
                  cooldown-ms = 150;
                  action = focus-workspace-up;
                };
                "Mod+Ctrl+WheelScrollDown" = {
                  cooldown-ms = 150;
                  action = move-column-to-workspace-down;
                };
                "Mod+Ctrl+WheelScrollUp" = {
                  cooldown-ms = 150;
                  action = move-column-to-workspace-up;
                };

                "Mod+WheelScrollRight".action = focus-column-right;
                "Mod+WheelScrollLeft".action = focus-column-left;
                "Mod+Ctrl+WheelScrollRight".action = move-column-right;
                "Mod+Ctrl+WheelScrollLeft".action = move-column-left;

                "Mod+Shift+WheelScrollDown".action = focus-column-right;
                "Mod+Shift+WheelScrollUp".action = focus-column-left;
                "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
                "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

                "Mod+1".action = focus-workspace 1;
                "Mod+2".action = focus-workspace 2;
                "Mod+3".action = focus-workspace 3;
                "Mod+4".action = focus-workspace 4;
                "Mod+5".action = focus-workspace 5;
                "Mod+6".action = focus-workspace 6;
                "Mod+7".action = focus-workspace 7;
                "Mod+8".action = focus-workspace 8;
                "Mod+9".action = focus-workspace 9;
                "Mod+Ctrl+1".action.move-column-to-workspace = 1;
                "Mod+Ctrl+2".action.move-column-to-workspace = 2;
                "Mod+Ctrl+3".action.move-column-to-workspace = 3;
                "Mod+Ctrl+4".action.move-column-to-workspace = 4;
                "Mod+Ctrl+5".action.move-column-to-workspace = 5;
                "Mod+Ctrl+6".action.move-column-to-workspace = 6;
                "Mod+Ctrl+7".action.move-column-to-workspace = 7;
                "Mod+Ctrl+8".action.move-column-to-workspace = 8;
                "Mod+Ctrl+9".action.move-column-to-workspace = 9;

                "Mod+BracketLeft".action = consume-or-expel-window-left;
                "Mod+BracketRight".action = consume-or-expel-window-right;

                "Mod+Comma".action = consume-window-into-column;
                "Mod+Period".action = expel-window-from-column;

                "Mod+R".action = switch-preset-column-width;
                "Mod+Shift+R".action = switch-preset-window-height;
                "Mod+Ctrl+R".action = reset-window-height;
                "Mod+F".action = maximize-column;
                "Mod+Shift+F".action = fullscreen-window;

                "Mod+Ctrl+F".action = expand-column-to-available-width;

                "Mod+C".action = center-column;

                "Mod+Ctrl+C".action = center-visible-columns;

                "Mod+Minus".action = set-column-width "-10%";
                "Mod+Plus".action = set-column-width "+10%";

                "Mod+Shift+Minus".action = set-window-height "-10%";
                "Mod+Shift+Plus".action = set-window-height "+10%";

                "Mod+V".action = toggle-window-floating;
                "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

                "Mod+W".action = toggle-column-tabbed-display;

                "Print".action.screenshot = [ ];
                "Ctrl+Print".action.screenshot-screen = [ ]; # Temp fix for https://github.com/sodiboo/niri-flake/issues/922
                "Alt+Print".action.screenshot-window = [ ];

                "Mod+Escape" = {
                  allow-inhibiting = false;
                  action = toggle-keyboard-shortcuts-inhibit;
                };

                "Mod+Shift+E".action = quit;
                "Ctrl+Alt+Delete".action = quit;

                "Mod+Shift+P".action = power-off-monitors;
              };
          };
        };
      };
  };
}
