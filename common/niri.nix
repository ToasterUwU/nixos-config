{
  lib,
  pkgs,
  config,
  niri,
  noctalia,
  ...
}:
{
  imports = [ noctalia.nixosModules.default ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  age.secrets = {
    "noctalia-hassio-settings.toml" = {
      file = ../secrets/common/noctalia-hassio-settings.toml.age;
      path = config.users.users.aki.home + "/.config/noctalia/hassio-secrets.toml";
      owner = "aki";
      group = "users";
      mode = "600";
    };
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

  systemd.user.services.niri-flake-polkit.serviceConfig.UnsetEnvironment = "QT_STYLE_OVERRIDE";

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "niri";
      appearance = {
        scheme = "Catppuccin";
        theme_mode = "dark";
        font_family = "Fira Code";
      };
      cursor.size = 24;
      keyboard.layout = "de";
    };
    cursorTheme = {
      package = pkgs.catppuccin-cursors.mochaPink;
      name = "catppuccin-mocha-pink-cursors";
    };
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  programs.kdeconnect.enable = true;
  programs.localsend.enable = true;

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

  # Needed for Nemo Networking
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    config.services.greetd.package

    xwayland-satellite

    nemo-with-extensions
    file-roller
    p7zip # For file roller multi part 7zip support
    xviewer
    pwvucontrol

    catppuccin-cursors.mochaPink

    # Noctalia Shell Plugin dependencies
    linux-wallpaperengine # w-engine

    grim
    slurp
    wl-clipboard
    tesseract
    imagemagick
    zbar
    curl
    translate-shell
    wl-screenrec
    ffmpeg
    gifski
    jq
    hyprpicker # screen-toolkit
    gpu-screen-recorder # screen-toolkit
    mpv # screen-toolkit
    pulseaudio # screen-toolkit, pactl for recording with audio
    bc # screen-toolkit
    # vpn-manager, only nm-connection-editor (the full package would autostart a second tray icon via nm-applet)
    (runCommand "nm-connection-editor" { } ''
      mkdir -p $out/bin
      ln -s ${networkmanagerapplet}/bin/nm-connection-editor $out/bin/
    '')
    zenity # vpn-manager, file picker for VPN imports
    fzf # file-search
    udiskie # udiskie
    sshfs # phone-connect
    glib # gdbus, used by phone-connect to talk to kdeconnectd (and file-search's reveal in file manager)
    gh # github-notifications
    ddcutil # DDC brightness
  ];

  programs.noctalia = {
    enable = true;

    # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
    recommendedServices.enable = true;
  };

  services.udisks2.enable = true; # USB drives for the udiskie plugin
  hardware.i2c.enable = true; # DDC brightness control for external monitors
  users.users.aki.extraGroups = [ "i2c" ];

  home-manager = {
    users.aki =
      { config, ... }:
      {
        imports = [
          noctalia.homeModules.default
          ./home-modules/noctalia-w-engine.nix
        ];
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
          # Real directories with per-file symlinks, so plugins like daily-wallpaper can write into it
          "Pictures/Backgrounds" = {
            source = ../assets/wallpapers;
            recursive = true;
          };
          ".gnome2/accels/nemo".text = ''
            (gtk_accel_path "<Actions>/DirViewActions/OpenInTerminal" "F4")
          '';
        };

        programs = {
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
          niri.settings = {
            environment."NIXOS_OZONE_WL" = "1";
            xwayland-satellite.enable = true;

            prefer-no-csd = true;

            spawn-at-startup =
              let
                # Block until Noctalias tray host owns the bus name that StatusNotifierItem clients look for
                wait-for-tray = pkgs.writeShellApplication {
                  name = "wait-for-tray";
                  runtimeInputs = [ pkgs.glib ];
                  text = ''
                    gdbus wait --session --timeout 30 org.kde.StatusNotifierWatcher
                  '';
                };

                # Block until a tiled window with the given app-id exists in niri
                wait-for-window = pkgs.writeShellApplication {
                  name = "wait-for-window";
                  runtimeInputs = [
                    pkgs.niri-unstable
                    pkgs.jq
                  ];
                  text = ''
                    deadline=$((SECONDS + 30))
                    until niri msg --json windows |
                      jq -e --arg id "$1" \
                        'any(.[]; .app_id == $id and .is_floating == false)' >/dev/null; do
                      [ "$SECONDS" -lt "$deadline" ] || exit 1
                      sleep 0.2
                    done
                  '';
                };

                afterTray = lib.getExe wait-for-tray;
                afterWindow = lib.getExe wait-for-window;
              in
              [
                { sh = lib.getExe config.programs.noctalia.package; }
                { sh = "${afterTray}; discord"; }
                { sh = "${afterTray}; ${afterWindow} discord; sable"; }
                { sh = "${afterTray}; openrgb --startminimized --profile Pink"; }
                { sh = "${afterTray}; easyeffects --hide-window"; }
                { sh = "${afterTray}; super-productivity"; }
              ];

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

              warp-mouse-to-focus.enable = false;

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

            # Blurred, tinted wallpaper copy from Noctalia as the overview backdrop
            layer-rules = [
              {
                matches = [ { namespace = "^noctalia-backdrop"; } ];
                place-within-backdrop = true;
              }
            ];

            window-rules = [
              {
                matches = [ { app-id = "^dev\\.noctalia\\.Noctalia$"; } ];
                open-floating = true;
                default-column-width.fixed = 1080;
                default-window-height.fixed = 920;
              }
            ];

            # Allows notification actions and window activation from Noctalia
            debug.honor-xdg-activation-with-invalid-serial = [ ];

            screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

            # https://github.com/YaLTeR/niri/wiki/Configuration:-Animations
            animations = {
              enable = true;
            };

            binds = with config.lib.niri.actions; {
              "Mod+Shift+Slash".action = show-hotkey-overlay;
              "Mod+T" = {
                hotkey-overlay.title = "Open a Terminal: alacritty";
                action = spawn-sh "${lib.getExe pkgs.alacritty}";
              };
              "Mod+D" = {
                hotkey-overlay.title = "Noctialia Shell Launcher";
                action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg panel-toggle launcher";
              };
              "Mod+X".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg panel-toggle session";
              "Mod+L" = {
                hotkey-overlay.title = "Lock the Screen";
                action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg session lock";
              };

              "XF86AudioRaiseVolume".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg volume-up";
              "XF86AudioLowerVolume".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg volume-down";
              "XF86AudioMute".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg volume-mute";
              "XF86AudioMicMute".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg mic-mute";

              "XF86AudioStop".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg media pause";
              "XF86AudioPlay".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg media toggle";
              "XF86AudioPrev".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg media previous";
              "XF86AudioNext".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg media next";

              "XF86MonBrightnessUp".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg brightness-up";
              "XF86MonBrightnessDown".action = spawn-sh "${lib.getExe config.programs.noctalia.package} msg brightness-down";

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
              # "Mod+L".action = focus-column-right;

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
              "Mod+Shift+F".action = set-window-height "100%";
              "Mod+Ctrl+Shift+F".action = set-window-height "50%";

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
          noctalia = {
            enable = true;
            settings = {
              shell = {
                font_family = "Fira Code";
                avatar_path = "/home/aki/.face";
                telemetry_enabled = true;
                show_location = false;
                niri_overview_type_to_launch_enabled = true; # Replaces the default workspace widget
                clipboard_auto_paste = "off";
                shadow.direction = "down_right";
                launcher.auto_paste = "off";
                session = {
                  show_shortcuts = true;
                  actions = [
                    {
                      action = "lock";
                      shortcut = "1";
                      countdown_seconds = 5;
                    }
                    {
                      action = "suspend";
                      shortcut = "2";
                      countdown_seconds = 5;
                    }
                    {
                      action = "command";
                      label = "Hibernate";
                      glyph = "zzz";
                      command = "systemctl hibernate";
                      shortcut = "3";
                      countdown_seconds = 5;
                    }
                    {
                      action = "reboot";
                      shortcut = "4";
                      countdown_seconds = 5;
                    }
                    {
                      action = "logout";
                      shortcut = "5";
                      countdown_seconds = 5;
                    }
                    {
                      action = "shutdown";
                      variant = "destructive";
                      shortcut = "6";
                      countdown_seconds = 5;
                    }
                    {
                      action = "reboot_uefi";
                      shortcut = "7";
                      countdown_seconds = 5;
                    }
                    {
                      action = "command";
                      label = "Userspace Reboot";
                      glyph = "refresh";
                      command = "systemctl soft-reboot";
                      shortcut = "8";
                      countdown_seconds = 5;
                    }
                  ];
                };
              };

              theme = {
                mode = "dark";
                source = "builtin";
                builtin = "Catppuccin";
                sync_color_scheme = true;
              };

              wallpaper = {
                enabled = true;
                directory = "${config.home.homeDirectory}/Pictures/Backgrounds";
                fill_mode = "crop";
                fill_color = "#000000";
                # Each monitor rotates independently (no per-monitor folder overrides, so all use `directory`)
                per_monitor_directories = true;
                transition = [
                  "diamond"
                  "disc"
                  "fade"
                  "golden"
                  "honeycomb"
                  "melt"
                  "pixel"
                  "stripes"
                  "vortex"
                  "wipe"
                  "zoom"
                ];
                transition_duration = 1500;
                edge_smoothness = 5.0e-2;
                transition_on_startup = true;
                automation = {
                  enabled = true;
                  interval_seconds = 300;
                  order = "random";
                };
              };

              # Blurred wallpaper in the niri overview, see the noctalia-backdrop layer-rule
              backdrop = {
                enabled = true;
                blur_intensity = 0.1;
                tint_intensity = 0.2;
              };

              bar = {
                order = [ "main" ];
                main = {
                  position = "top";
                  background_opacity = 0.93;
                  margin_ends = 0;
                  margin_edge = 0;
                  concave_edge_corners = true;
                  radius = 12;
                  widget_spacing = 6;
                  capsule = true;
                  start = [
                    "control-center"
                    "launcher"
                    "settings"
                    "stack"
                    "screen-toolkit"
                    "obs-control"
                    "w-engine"
                    "phone-connect"
                    "hassio"
                    "spacer20"
                    "rss"
                    "github"
                    "spacer20"
                    "group:sysmon"
                    "spacer20"
                    "calculator"
                    "clipboard"
                    "file-search"
                  ];
                  center = [
                    "group:g1"
                    "next-task"
                  ];
                  end = [
                    "lock_keys"
                    "privacy"
                    "spacer20"
                    "network"
                    "vpn"
                    "bluetooth"
                    "battery"
                    "power_profile"
                    "volume"
                    "brightness"
                    "usb"
                    "spacer20"
                    "tray"
                    "weather"
                    "timer"
                    "clock"
                    "notifications"
                  ];
                  capsule_group = [
                    {
                      id = "sysmon";
                      members = [
                        "cpu"
                        "temp"
                        "ram"
                      ];
                    }
                    {
                      id = "g1";
                      members = [
                        "media"
                        "audio_visualizer"
                      ];
                    }
                  ];
                };
              };

              widget = {
                control-center = {
                  custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                };
                launcher = {
                  glyph = "rocket";
                  color = "primary";
                };
                spacer20 = {
                  type = "spacer";
                  length = 20;
                };
                temp.show_value = false;
                media = {
                  max_length = 300;
                  artist_first = true;
                  title_scroll = "always";
                  hide_when_no_media = true;
                };
                lock_keys = {
                  show_caps_lock = true;
                  show_num_lock = true;
                  show_scroll_lock = true;
                };
                privacy.active_color = "error";
                network.show_label = false;
                battery.display_mode = "graphic";
                volume.actions.middle = "exec pwvucontrol || pavucontrol";
                tray = {
                  pinned = [ "steam" ];
                  hide_passive = false;
                };
                clock = {
                  format = "{:%H:%M %a, %b %d}";
                  tooltip_format = "{:%H:%M %a, %b %d}";
                  color = "primary";
                };
                notifications.hide_when_no_unread = false;
                weather.show_condition = false;

                # Plugin widgets
                screen-toolkit.type = "alexander/screen-toolkit:widget";
                obs-control.type = "ayagmar/obs-control:status";
                w-engine.type = "tadomika_ari/w-engine:w-engine-widget";
                phone-connect.type = "icefish/phone-connect:bar";
                hassio.type = "pozzoo/hassio:status";
                rss.type = "nilsonlinux/rss-notifier:badge";
                github.type = "hy4ri/github-notifications:inbox";
                calculator.type = "yuuto/calculator:bar";
                file-search.type = "nightwatch75/file-search:file-search";
                vpn.type = "andrewdems/vpn-manager:bar";
                usb.type = "aristides/udiskie:status";
                audio_visualizer = {
                  enabled = false;
                  mirrored = false;
                };
                next-task.type = "redxtech/super-productivity:next-task";
                stack = {
                  type = "johnnyp0t/niri-workspace-stack:stack";
                  displayMode = "mini_map";
                  show_empty = false;
                };
                timer = {
                  type = "noctalia/timer:bar";
                  show_idle_on_horizontal = false;
                };
              };

              control_center.shortcuts = [
                { type = "wifi"; }
                { type = "bluetooth"; }
                { type = "power_profile"; }
                { type = "notification"; }
                { type = "caffeine"; }
                { type = "wallpaper"; }
              ];

              notification = {
                position = "top_right";
                layer = "overlay";
                background_opacity = 1.0;
                keep_dismissed_in_history = false;
              };

              osd = {
                position = "top_right";
                hide_delay_ms = 2000;
                background_opacity = 1.0;
                kinds.media = false;
              };

              audio = {
                enable_overdrive = true;
                enable_sounds = false;
              };

              brightness.enable_ddcutil = true;
              bluetooth.connect_when_enabled = true;
              location.auto_locate = true;
              weather = {
                enabled = true;
                unit = "metric";
              };

              idle = {
                pre_action_fade_seconds = 5;
                behavior = {
                  screen-off = {
                    action = "screen_off";
                    timeout = 600;
                    enabled = true;
                  };
                  lock = {
                    action = "lock";
                    timeout = 660;
                    enabled = true;
                  };
                  lock-and-suspend = {
                    action = "lock_and_suspend";
                    enabled = false;
                  };
                };
              };

              lockscreen = {
                blur_intensity = 0.2;
                tint_intensity = 0.0;
                transition = [ ];
              };

              desktop_widgets.enabled = false;

              system.monitor = {
                cpu_usage_activity_threshold = 80;
                cpu_usage_critical_threshold = 90;
                cpu_temp_activity_threshold = 80;
                cpu_temp_critical_threshold = 90;
                ram_pct_activity_threshold = 80;
                ram_pct_critical_threshold = 90;
                disk_used_pct_activity_threshold = 80;
                disk_used_pct_critical_threshold = 90;
                swap_pct_activity_threshold = 80;
                swap_pct_critical_threshold = 90;
                gpu_temp_activity_threshold = 80;
                gpu_temp_critical_threshold = 90;
                gpu_usage_activity_threshold = 80;
                gpu_usage_critical_threshold = 90;
              };

              plugins = {
                auto_update = "all";
                enabled = [
                  "alexander/screen-toolkit"
                  "andrewdems/vpn-manager"
                  "aristides/udiskie"
                  "ayagmar/obs-control"
                  "hy4ri/github-notifications"
                  "icefish/phone-connect"
                  "johnnyp0t/niri-workspace-stack"
                  "nightwatch75/file-search"
                  "nilsonlinux/rss-notifier"
                  "noctalia/timer"
                  "pozzoo/hassio"
                  "redxtech/super-productivity"
                  "tadomika_ari/w-engine"
                  "yuuto/calculator"
                ];
              };

              plugin_settings = {
                "alexander/screen-toolkit".selected-ocr-lang = "eng";
                "aristides/udiskie" = {
                  enable_notifications = true;
                  file_manager_cmd = "nemo";
                };
                "ayagmar/obs-control".python_executable = lib.getExe (
                  pkgs.python3.withPackages (ps: [ ps.websocket-client ])
                );
                "nightwatch75/file-search".exclude_dirs = ".git, node_modules, .cache, .venv, NAS"; # Ignore sshfs NAS mounts
                "redxtech/super-productivity" = {
                  auto_start = true;
                  notify_due = true;
                };
                "nilsonlinux/rss-notifier" = {
                  feeds = [ "https://www.lttlabs.com/articles/rss.xml" ];
                  refresh_minutes = 10;
                  notify_new = false;
                };
                # Per-screen wallpapers are set via programs.noctalia-w-engine in the host configs
                "tadomika_ari/w-engine".sync_colors = false;
                # ha_url and ha_token come from the hassio-secrets.toml agenix secret
              };
            };
          };

          noctalia-w-engine.engine = {
            scaling = "fill";
            clamp = "clamp";
            fps = 30;
            volume = 0;
            silent = true;
            no_audio_processing = true;
            fullscreen_pause_only_active = true;
          };
        };
      };
  };
}
