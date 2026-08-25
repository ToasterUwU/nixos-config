{
  lib,
  pkgs,
  config,
  niri,
  noctalia,
  ...
}:
{
  nixpkgs.overlays = [ niri.overlays.niri ];

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  age.secrets = {
    "noctalia-github-feed-settings.json" = {
      file = ../secrets/common/noctalia-github-feed-settings.json.age;
      path = config.users.users.aki.home + "/.config/noctalia/plugins/github-feed/settings.json";
      owner = "aki";
      group = "users";
      mode = "600";
    };
    "noctalia-hassio-settings.json" = {
      file = ../secrets/common/noctalia-hassio-settings.json.age;
      path = config.users.users.aki.home + "/.config/noctalia/plugins/hassio/settings.json";
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
    xviewer
    pwvucontrol

    catppuccin-cursors.mochaPink

    # Noctalia Shell Plugin dependencies
    linux-wallpaperengine

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
  ];

  networking.networkmanager.enable = true; # Networking widgets for noctalia
  hardware.bluetooth.enable = true; # Bluetooth widgets for noctalia
  services.tuned.enable = true; # Power widgets for noctalia
  services.upower.enable = true; # Battery widgets for noctalia
  services = {
    gnome.evolution-data-server.enable = true; # Events in Noctalia Calender
  };

  home-manager = {
    users.aki =
      { config, ... }:
      {
        imports = [ noctalia.homeModules.default ];
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
                { sh = "noctalia-shell"; }
                { sh = "${afterTray}; discord"; }
                { sh = "${afterTray}; ${afterWindow} discord; sable"; }
                { sh = "${afterTray}; openrgb --startminimized --profile Pink"; }
                { sh = "${afterTray}; easyeffects --hide-window"; }
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
                action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call launcher toggle";
              };
              "Mod+X".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call sessionMenu toggle";
              "Mod+L" = {
                hotkey-overlay.title = "Lock the Screen";
                action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call lockScreen lock";
              };

              "XF86AudioRaiseVolume".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call volume increase";
              "XF86AudioLowerVolume".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call volume decrease";
              "XF86AudioMute".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call volume muteOutput";
              "XF86AudioMicMute".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call volume muteInput";

              "XF86AudioStop".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call media pause";
              "XF86AudioPlay".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call media playPause";
              "XF86AudioPrev".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call media previous";
              "XF86AudioNext".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call media next";

              "XF86MonBrightnessUp".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call brightness increase";
              "XF86MonBrightnessDown".action = spawn-sh "${lib.getExe config.programs.noctalia-shell.package} ipc call brightness decrease";

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
          noctalia-shell = {
            enable = true;
            package =
              (pkgs.noctalia-shell.override {
                calendarSupport = true;
                gpuScreenRecorderSupport = true;
              }).overrideAttrs
                (old: {
                  buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.qt6.qtwebsockets ];
                });
            plugins = {
              sources = [
                {
                  enabled = true;
                  name = "Noctalia Plugins";
                  url = "https://github.com/noctalia-dev/noctalia-plugins";
                }
              ];
              states = {
                activate-linux = {
                  enabled = false;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                clipper = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                coin-flip = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                daily-wallpaper = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                file-search = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                github-feed = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                hassio = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                kde-connect = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                linux-wallpaperengine-controller = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                network-manager-vpn = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                niri-auto-tile = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                niri-overview-launcher = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                niri-workspaces = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                noctalia-calculator = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                obs-control = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                privacy-indicator = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                rss-feed = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                screen-toolkit = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                timer = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                usb-drive-manager = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                weather-indicator = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
              };
              version = 2;
            };
            pluginSettings = {
              clipper = {
                enableTodoIntegration = false;
                pincardsEnabled = true;
                notecardsEnabled = true;
                showCloseButton = true;
                fullscreenMode = false;
                hidePanelBackground = false;
                autoPaste = false;
                autoPasteOnRightClick = false;
                autoPasteDelay = 300;
                panelWidth = 1100;
                panelHeight = 0;
                cardColors = { };
                customColors = { };
              };
              coin-flip = {
                iconColor = "mPrimary";
                delay = 11;
                lastResult = "Tails";
              };
              daily-wallpaper = {
                source = "nasa";
                locale = "en-US";
              };
              linux-wallpaperengine-controller = {
                wallpapersFolder = "~/.local/share/Steam/steamapps/workshop/content/431960";
                assetsDir = "";
                iconColor = "none";
                enableExtraPropertiesEditor = true;
                defaultScaling = "fill";
                defaultClamp = "clamp";
                defaultFps = 30;
                defaultVolume = 0;
                defaultMuted = true;
                defaultAudioReactiveEffects = false;
                defaultNoAutomute = false;
                defaultDisableMouse = false;
                defaultDisableParallax = false;
                applyWallpaperColorsOnApply = false;
                wallpaperColorScreenshots = { };
                defaultNoFullscreenPause = false;
                defaultFullscreenPauseOnlyActive = true;
                autoApplyOnStartup = true;
                wallpaperScanCacheMinutes = 5;
                panelLastSelectedPath = "";
                wallpaperProperties = { };
                runtimeRecoveryPending = false;
              };
              network-manager-vpn = {
                displayMode = "onhover";
                disconnectedColor = "secondary";
                connectedColor = "tertiary";
                disableToastNotifications = false;
              };
              niri-auto-tile = {
                maxVisible = 1;
                debounceMs = 300;
                maxEventsPerSecond = 20;
                enabled = false;
                perWorkspace = true;
                workspaceMaxVisible = { };
                language = "auto";
                onlyAtMax = true;
              };
              privacy-indicator = {
                hideInactive = false;
                enableToast = false;
                removeMargins = false;
                iconSpacing = 4;
                activeColor = "error";
                inactiveColor = "none";
                micFilterRegex = "";
                camFilterRegex = "";
              };
              rss-feed = {
                feeds = [
                  {
                    name = "LTT Labs";
                    url = "https://www.lttlabs.com/articles/rss.xml";
                  }
                ];
                updateInterval = 600;
                maxItemsPerFeed = 10;
                showOnlyUnread = true;
                markAsReadOnClick = true;
                readItems = [ ];
              };
              screen-toolkit = {
                colorHistory = [ ];
                paletteColors = [ ];
                installedLangs = [ "eng" ];
                transAvailable = false;
                selectedOcrLang = "eng";
                screenshotPath = "";
                videoPath = "";
                filenameFormat = "";
                detectedRecorder = "";
                detectedCompositor = "niri";
                stateIsRunning = false;
                stateActiveTool = "";
                stateMirrorVisible = false;
              };
              timer = {
                defaultDuration = 0;
                compactMode = false;
                iconColor = "none";
                textColor = "primary";
              };
            };
            settings = {
              appLauncher = {
                autoPasteClipboard = false;
                clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
                clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
                clipboardWrapText = true;
                customLaunchPrefix = "";
                customLaunchPrefixEnabled = false;
                density = "default";
                enableClipPreview = true;
                enableClipboardChips = true;
                enableClipboardHistory = true;
                enableClipboardSmartIcons = true;
                enableSessionSearch = true;
                enableSettingsSearch = true;
                enableWindowsSearch = true;
                iconMode = "tabler";
                ignoreMouseInput = false;
                overviewLayer = true;
                pinnedApps = [ ];
                position = "center";
                screenshotAnnotationTool = "";
                showCategories = true;
                showIconBackground = false;
                sortByMostUsed = true;
                terminalCommand = "alacritty -e";
                viewMode = "list";
              };
              audio = {
                mprisBlacklist = [ ];
                preferredPlayer = "supersonic";
                spectrumFrameRate = 30;
                spectrumMirrored = true;
                visualizerType = "linear";
                volumeFeedback = false;
                volumeFeedbackSoundFile = "";
                volumeOverdrive = true;
                volumeStep = 5;
              };
              bar = {
                autoHideDelay = 500;
                autoShowDelay = 150;
                backgroundOpacity = 0.93;
                barType = "simple";
                capsuleColorKey = "none";
                capsuleOpacity = 1;
                contentPadding = 2;
                displayMode = "always_visible";
                enableExclusionZoneInset = true;
                fontScale = 1;
                frameRadius = 12;
                frameThickness = 8;
                hideOnOverview = false;
                marginHorizontal = 4;
                marginVertical = 4;
                middleClickAction = "none";
                middleClickCommand = "";
                middleClickFollowMouse = false;
                monitors = [ ];
                mouseWheelAction = "none";
                mouseWheelWrap = true;
                outerCorners = true;
                position = "top";
                reverseScroll = false;
                rightClickAction = "controlCenter";
                rightClickCommand = "";
                rightClickFollowMouse = true;
                screenOverrides = [ ];
                showCapsule = true;
                showOnWorkspaceSwitch = true;
                showOutline = false;
                useSeparateOpacity = false;
                widgetSpacing = 6;
                widgets = {
                  center = [
                    {
                      compactMode = false;
                      hideMode = "hidden";
                      hideWhenIdle = false;
                      id = "MediaMini";
                      maxWidth = 500;
                      panelShowAlbumArt = true;
                      scrollingMode = "always";
                      showAlbumArt = true;
                      showArtistFirst = true;
                      showProgressRing = true;
                      showVisualizer = true;
                      textColor = "none";
                      useFixedWidth = false;
                      visualizerType = "linear";
                    }
                  ];
                  left = [
                    {
                      colorizeDistroLogo = false;
                      colorizeSystemIcon = "primary";
                      colorizeSystemText = "none";
                      customIconPath = "";
                      enableColorization = true;
                      icon = "noctalia";
                      id = "ControlCenter";
                      useDistroLogo = true;
                    }
                    {
                      colorizeSystemIcon = "none";
                      colorizeSystemText = "none";
                      customIconPath = "";
                      enableColorization = false;
                      icon = "rocket";
                      iconColor = "primary";
                      id = "Launcher";
                      useDistroLogo = false;
                    }
                    {
                      iconColor = "none";
                      id = "Settings";
                    }
                    {
                      characterCount = 2;
                      colorizeIcons = false;
                      emptyColor = "none";
                      enableScrollWheel = true;
                      focusedColor = "primary";
                      followFocusedScreen = false;
                      fontWeight = "bold";
                      groupedBorderOpacity = 1;
                      hideUnoccupied = false;
                      iconScale = 0.8;
                      id = "Workspace";
                      labelMode = "index";
                      occupiedColor = "secondary";
                      pillSize = 0.6000000000000001;
                      showApplications = true;
                      showApplicationsHover = false;
                      showBadge = true;
                      showLabelsOnlyWhenOccupied = true;
                      unfocusedIconsOpacity = 1;
                    }
                    { id = "plugin:niri-auto-tile"; }
                    { id = "plugin:screen-toolkit"; }
                    { id = "plugin:obs-control"; }
                    {
                      defaultSettings = {
                        applyWallpaperColorsOnApply = false;
                        assetsDir = "";
                        autoApplyOnStartup = true;
                        defaultAudioReactiveEffects = true;
                        defaultClamp = "clamp";
                        defaultDisableMouse = false;
                        defaultDisableParallax = false;
                        defaultFps = 30;
                        defaultFullscreenPauseOnlyActive = false;
                        defaultMuted = true;
                        defaultNoAutomute = false;
                        defaultNoFullscreenPause = false;
                        defaultScaling = "fill";
                        defaultVolume = 100;
                        enableExtraPropertiesEditor = true;
                        iconColor = "none";
                        lastKnownGoodScreens = { };
                        panelLastSelectedPath = "";
                        runtimeRecoveryPending = false;
                        screens = { };
                        wallpaperColorScreenshots = { };
                        wallpaperProperties = { };
                        wallpaperScanCacheMinutes = 5;
                        wallpapersFolder = "~/.local/share/Steam/steamapps/workshop/content/431960";
                      };
                      id = "plugin:linux-wallpaperengine-controller";
                    }
                    {
                      defaultSettings = { };
                      id = "plugin:kde-connect";
                    }
                    { id = "plugin:hassio"; }
                    {
                      id = "Spacer";
                      width = 20;
                    }
                    { id = "plugin:rss-feed"; }
                    { id = "plugin:github-feed"; }
                    {
                      id = "Spacer";
                      width = 20;
                    }
                    {
                      compactMode = true;
                      diskPath = "/";
                      iconColor = "none";
                      id = "SystemMonitor";
                      showCpuCores = false;
                      showCpuFreq = false;
                      showCpuTemp = true;
                      showCpuUsage = true;
                      showDiskAvailable = false;
                      showDiskUsage = true;
                      showDiskUsageAsPercent = true;
                      showGpuTemp = false;
                      showLoadAverage = false;
                      showMemoryAsPercent = false;
                      showMemoryUsage = true;
                      showNetworkStats = true;
                      showSwapUsage = false;
                      textColor = "none";
                      useMonospaceFont = true;
                      usePadding = false;
                    }
                    {
                      id = "Spacer";
                      width = 20;
                    }
                    { id = "plugin:noctalia-calculator"; }
                    { id = "plugin:clipper"; }
                    {
                      defaultSettings = {
                        iconColor = "mPrimary";
                      };
                      id = "plugin:coin-flip";
                    }
                  ];
                  right = [
                    {
                      capsLockIcon = "letter-c";
                      hideWhenOff = false;
                      id = "LockKeys";
                      numLockIcon = "letter-n";
                      scrollLockIcon = "letter-s";
                      showCapsLock = true;
                      showNumLock = true;
                      showScrollLock = true;
                    }
                    { id = "plugin:privacy-indicator"; }
                    {
                      id = "Spacer";
                      width = 20;
                    }
                    {
                      displayMode = "onhover";
                      iconColor = "none";
                      id = "Network";
                      textColor = "none";
                    }
                    {
                      defaultSettings = {
                        connectedColor = "primary";
                        disconnectedColor = "none";
                        displayMode = "always_visible";
                      };
                      id = "plugin:network-manager-vpn";
                    }
                    {
                      displayMode = "onhover";
                      iconColor = "none";
                      id = "Bluetooth";
                      textColor = "none";
                    }
                    {
                      deviceNativePath = "__default__";
                      displayMode = "graphic-clean";
                      hideIfIdle = false;
                      hideIfNotDetected = true;
                      id = "Battery";
                      showNoctaliaPerformance = false;
                      showPowerProfiles = false;
                    }
                    {
                      iconColor = "none";
                      id = "PowerProfile";
                    }
                    {
                      displayMode = "alwaysShow";
                      iconColor = "none";
                      id = "Volume";
                      middleClickCommand = "pwvucontrol || pavucontrol";
                      textColor = "none";
                    }
                    {
                      applyToAllMonitors = false;
                      displayMode = "alwaysShow";
                      iconColor = "none";
                      id = "Brightness";
                      textColor = "none";
                    }
                    {
                      defaultSettings = {
                        autoMount = false;
                        fileBrowser = "nemo";
                        hideWhenEmpty = false;
                        iconColor = "none";
                        showBadge = false;
                        showNotifications = true;
                        terminalCommand = "alacritty";
                      };
                      id = "plugin:usb-drive-manager";
                    }
                    {
                      id = "Spacer";
                      width = 20;
                    }
                    {
                      blacklist = [ ];
                      chevronColor = "none";
                      colorizeIcons = false;
                      drawerEnabled = false;
                      hidePassive = false;
                      id = "Tray";
                      pinned = [ "steam" ];
                    }
                    {
                      defaultSettings = {
                        customColor = "none";
                        showConditionIcon = true;
                        showTempUnit = true;
                        showTempValue = true;
                        tooltipOption = "everything";
                      };
                      id = "plugin:weather-indicator";
                    }
                    {
                      defaultSettings = {
                        compactMode = false;
                        defaultDuration = 0;
                        iconColor = "none";
                        textColor = "none";
                      };
                      id = "plugin:timer";
                    }
                    {
                      clockColor = "primary";
                      customFont = "";
                      formatHorizontal = "HH:mm ddd, MMM dd";
                      formatVertical = "HH mm - dd MM";
                      id = "Clock";
                      tooltipFormat = "HH:mm ddd, MMM dd";
                      useCustomFont = false;
                    }
                    {
                      hideWhenZero = false;
                      hideWhenZeroUnread = false;
                      iconColor = "none";
                      id = "NotificationHistory";
                      showUnreadBadge = true;
                      unreadBadgeColor = "primary";
                    }
                  ];
                };
              };
              brightness = {
                backlightDeviceMappings = [ ];
                brightnessStep = 5;
                enableDdcSupport = true;
                enforceMinimum = true;
              };
              calendar = {
                cards = [
                  {
                    enabled = true;
                    id = "calendar-header-card";
                  }
                  {
                    enabled = true;
                    id = "calendar-month-card";
                  }
                  {
                    enabled = true;
                    id = "weather-card";
                  }
                ];
              };
              colorSchemes = {
                darkMode = true;
                generationMethod = "tonal-spot";
                manualSunrise = "06:30";
                manualSunset = "18:30";
                monitorForColors = "";
                predefinedScheme = "Catppuccin";
                schedulingMode = "off";
                syncGsettings = true;
                useWallpaperColors = false;
              };
              controlCenter = {
                cards = [
                  {
                    enabled = true;
                    id = "profile-card";
                  }
                  {
                    enabled = true;
                    id = "shortcuts-card";
                  }
                  {
                    enabled = true;
                    id = "audio-card";
                  }
                  {
                    enabled = true;
                    id = "brightness-card";
                  }
                  {
                    enabled = true;
                    id = "weather-card";
                  }
                  {
                    enabled = true;
                    id = "media-sysmon-card";
                  }
                ];
                diskPath = "/";
                position = "close_to_bar_button";
                shortcuts = {
                  left = [
                    { id = "Network"; }
                    { id = "Bluetooth"; }
                    { id = "PowerProfile"; }
                  ];
                  right = [
                    { id = "Notifications"; }
                    { id = "KeepAwake"; }
                    { id = "NoctaliaPerformance"; }
                    { id = "WallpaperSelector"; }
                  ];
                };
              };
              desktopWidgets = {
                enabled = false;
                gridSnap = false;
                gridSnapScale = false;
                monitorWidgets = [ ];
                overviewEnabled = true;
              };
              dock = {
                animationSpeed = 1;
                backgroundOpacity = 1;
                colorizeIcons = false;
                deadOpacity = 0.6;
                displayMode = "auto_hide";
                dockType = "floating";
                enabled = false;
                floatingRatio = 1;
                groupApps = false;
                groupClickAction = "cycle";
                groupContextMenuMode = "extended";
                groupIndicatorStyle = "dots";
                inactiveIndicators = false;
                indicatorColor = "primary";
                indicatorOpacity = 0.6;
                indicatorThickness = 3;
                launcherIcon = "";
                launcherIconColor = "none";
                launcherPosition = "end";
                launcherUseDistroLogo = false;
                monitors = [ ];
                onlySameOutput = true;
                pinnedApps = [ ];
                pinnedStatic = false;
                position = "bottom";
                showDockIndicator = false;
                showLauncherIcon = false;
                sitOnFrame = false;
                size = 1;
              };
              general = {
                allowPanelsOnScreenWithoutBar = true;
                allowPasswordWithFprintd = false;
                animationDisabled = false;
                animationSpeed = 1;
                autoStartAuth = false;
                avatarImage = "/home/aki/.face";
                boxRadiusRatio = 1;
                clockFormat = "hh\nmm";
                clockStyle = "custom";
                compactLockScreen = false;
                dimmerOpacity = 0.2;
                enableBlurBehind = true;
                enableLockScreenCountdown = true;
                enableLockScreenMediaControls = false;
                enableShadows = true;
                forceBlackScreenCorners = false;
                iRadiusRatio = 1;
                keybinds = {
                  keyDown = [ "Down" ];
                  keyEnter = [
                    "Return"
                    "Enter"
                  ];
                  keyEscape = [ "Esc" ];
                  keyLeft = [ "Left" ];
                  keyRemove = [ "Del" ];
                  keyRight = [ "Right" ];
                  keyUp = [ "Up" ];
                };
                language = "";
                lockOnSuspend = true;
                lockScreenAnimations = false;
                lockScreenBlur = 0.2;
                lockScreenCountdownDuration = 10000;
                lockScreenMonitors = [ ];
                lockScreenTint = 0;
                passwordChars = false;
                radiusRatio = 1;
                reverseScroll = false;
                scaleRatio = 1;
                screenRadiusRatio = 1;
                shadowDirection = "bottom_right";
                shadowOffsetX = 2;
                shadowOffsetY = 3;
                showChangelogOnStartup = true;
                showHibernateOnLockScreen = false;
                showScreenCorners = false;
                showSessionButtonsOnLockScreen = true;
                smoothScrollEnabled = true;
                telemetryEnabled = true;
              };
              hooks = {
                colorGeneration = "";
                darkModeChange = "";
                enabled = false;
                performanceModeDisabled = "";
                performanceModeEnabled = "";
                screenLock = "";
                screenUnlock = "";
                session = "";
                startup = "";
                wallpaperChange = "";
              };
              idle = {
                customCommands = "[]";
                enabled = true;
                fadeDuration = 5;
                lockCommand = "";
                lockTimeout = 660;
                resumeLockCommand = "";
                resumeScreenOffCommand = "";
                resumeSuspendCommand = "echo \"Dont Suspend\"";
                screenOffCommand = "";
                screenOffTimeout = 600;
                suspendCommand = "echo \"Dont Suspend\"";
                suspendTimeout = 0;
              };
              location = {
                analogClockInCalendar = false;
                autoLocate = true;
                firstDayOfWeek = -1;
                hideWeatherCityName = true;
                hideWeatherTimezone = false;
                name = "My Location";
                showCalendarEvents = true;
                showCalendarWeather = true;
                showWeekNumberInCalendar = false;
                use12hourFormat = false;
                useFahrenheit = false;
                weatherEnabled = true;
                weatherShowEffects = true;
                weatherTaliaMascotAlways = false;
              };
              network = {
                bluetoothAutoConnect = true;
                bluetoothDetailsViewMode = "grid";
                bluetoothHideUnnamedDevices = false;
                bluetoothRssiPollIntervalMs = 60000;
                bluetoothRssiPollingEnabled = false;
                disableDiscoverability = false;
                networkPanelView = "wifi";
                wifiDetailsViewMode = "grid";
              };
              nightLight = {
                autoSchedule = true;
                dayTemp = "6500";
                enabled = false;
                forced = false;
                manualSunrise = "06:30";
                manualSunset = "18:30";
                nightTemp = "4000";
              };
              noctaliaPerformance = {
                disableDesktopWidgets = true;
                disableWallpaper = false;
              };
              notifications = {
                backgroundOpacity = 1;
                clearDismissed = true;
                criticalUrgencyDuration = 30;
                density = "default";
                enableBatteryToast = true;
                enableKeyboardLayoutToast = true;
                enableMarkdown = true;
                enableMediaToast = false;
                enabled = true;
                location = "top_right";
                lowUrgencyDuration = 3;
                monitors = [ "DP-3" ];
                normalUrgencyDuration = 8;
                overlayLayer = true;
                respectExpireTimeout = false;
                saveToHistory = {
                  critical = true;
                  low = true;
                  normal = true;
                };
                sounds = {
                  criticalSoundFile = "";
                  enabled = false;
                  excludedApps = "discord,firefox,chrome,chromium,edge";
                  lowSoundFile = "";
                  normalSoundFile = "";
                  separateSounds = false;
                  volume = 0.5;
                };
              };
              osd = {
                autoHideMs = 2000;
                backgroundOpacity = 1;
                enabled = true;
                enabledTypes = [
                  0
                  1
                  2
                ];
                location = "top_right";
                monitors = [ ];
                overlayLayer = true;
              };
              plugins = {
                autoUpdate = true;
                notifyUpdates = true;
              };
              sessionMenu = {
                countdownDuration = 5000;
                enableCountdown = true;
                largeButtonsLayout = "single-row";
                largeButtonsStyle = true;
                position = "center";
                powerOptions = [
                  {
                    action = "lock";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "1";
                  }
                  {
                    action = "suspend";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "2";
                  }
                  {
                    action = "hibernate";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "3";
                  }
                  {
                    action = "reboot";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "4";
                  }
                  {
                    action = "logout";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "5";
                  }
                  {
                    action = "shutdown";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "6";
                  }
                  {
                    action = "rebootToUefi";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "7";
                  }
                  {
                    action = "userspaceReboot";
                    command = "";
                    countdownEnabled = true;
                    enabled = true;
                    keybind = "8";
                  }
                ];
                showHeader = true;
                showKeybinds = true;
              };
              settingsVersion = 59;
              systemMonitor = {
                batteryCriticalThreshold = 5;
                batteryWarningThreshold = 20;
                cpuCriticalThreshold = 90;
                cpuWarningThreshold = 80;
                criticalColor = "";
                diskAvailCriticalThreshold = 10;
                diskAvailWarningThreshold = 20;
                diskCriticalThreshold = 90;
                diskWarningThreshold = 80;
                enableDgpuMonitoring = true;
                externalMonitor = "allarcritty -e btm";
                gpuCriticalThreshold = 90;
                gpuWarningThreshold = 80;
                memCriticalThreshold = 90;
                memWarningThreshold = 80;
                swapCriticalThreshold = 90;
                swapWarningThreshold = 80;
                tempCriticalThreshold = 90;
                tempWarningThreshold = 80;
                useCustomColors = false;
                warningColor = "";
              };
              templates = {
                activeTemplates = [ ];
                enableUserTheming = false;
              };
              ui = {
                boxBorderEnabled = false;
                fontDefault = "Fira Code";
                fontDefaultScale = 1;
                fontFixed = "FiraCode Nerd Font Mono";
                fontFixedScale = 1;
                panelBackgroundOpacity = 0.93;
                panelsAttachedToBar = true;
                scrollbarAlwaysVisible = true;
                settingsPanelMode = "attached";
                settingsPanelSideBarCardStyle = false;
                tooltipsEnabled = true;
                translucentWidgets = false;
              };
              wallpaper = {
                automationEnabled = true;
                directory = ../assets/wallpapers;
                enableMultiMonitorDirectories = true;
                enabled = true;
                favorites = [ ];
                fillColor = "#000000";
                fillMode = "crop";
                hideWallpaperFilenames = false;
                linkLightAndDarkWallpapers = true;
                monitorDirectories = [ ];
                overviewBlur = 0.1;
                overviewEnabled = true;
                overviewTint = 0.2;
                panelPosition = "follow_bar";
                randomIntervalSec = 300;
                setWallpaperOnAllMonitors = false;
                showHiddenFiles = false;
                skipStartupTransition = false;
                solidColor = "#1a1a2e";
                sortOrder = "name";
                transitionDuration = 1500;
                transitionEdgeSmoothness = 5.0e-2;
                transitionType = [
                  "fade"
                  "disc"
                  "stripes"
                  "wipe"
                  "honeycomb"
                ];
                useOriginalImages = true;
                useSolidColor = false;
                useWallhaven = false;
                viewMode = "browse";
                wallhavenApiKey = "";
                wallhavenCategories = "111";
                wallhavenOrder = "desc";
                wallhavenPurity = "100";
                wallhavenQuery = "";
                wallhavenRatios = "";
                wallhavenResolutionHeight = "";
                wallhavenResolutionMode = "atleast";
                wallhavenResolutionWidth = "";
                wallhavenSorting = "relevance";
                wallpaperChangeMode = "random";
              };
            };
          };
        };
      };
  };
}
