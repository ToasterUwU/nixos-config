{
  pkgs,
  config,
  catppuccin,
  lib,
  nixcord,
  ...
}:
{
  age.secrets = {
    "aki-id_ed25519" = {
      file = ../secrets/common/aki-id_ed25519.age;
      path = "/home/aki/.ssh/id_ed25519";
      owner = "aki";
      group = "users";
      mode = "600";
    };
    "aki-id_ed25519.pub" = {
      file = ../secrets/common/aki-id_ed25519.pub.age;
      path = "/home/aki/.ssh/id_ed25519.pub";
      owner = "aki";
      group = "users";
      mode = "644";
    };

    "aki-.wakatime.cfg" = {
      file = ../secrets/common/aki-.wakatime.cfg.age;
      path = "/home/aki/.wakatime.cfg";
      owner = "aki";
      group = "users";
      mode = "600";
    };
  };

  programs.fuse.userAllowOther = true;

  # Fix for FHS wrapped software thinking the permissions and ownership of the ssh config are mangled
  nixpkgs.overlays = [
    (final: prev: {
      openssh = prev.openssh.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../assets/openssh-nocheckcfg.patch ];
        doCheck = false;
      });
    })
  ];

  home-manager = {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      catppuccin.homeModules.catppuccin
      nixcord.homeModules.nixcord
    ];

    users.aki = {
      home.stateVersion = "23.11";

      systemd.user.services."sshfs-aki-home" = {
        Unit = {
          Description = "SSHFS Mount for Akis Home";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${pkgs.sshfs}/bin/sshfs -f -o delay_connect,reconnect,ServerAliveInterval=10,ServerAliveCountMax=2,_netdev,user,transform_symlinks,IdentityFile=/home/aki/.ssh/id_ed25519,allow_other,default_permissions,uid=${lib.toString config.users.users.aki.uid},gid=${
            lib.toString config.users.groups.${lib.toString config.users.users.aki.group}.gid
          },exec Aki@toasteruwu.com:/home /home/aki/NAS/home";
          ExecStop = "${pkgs.fuse}/bin/fusermount -u /home/aki/NAS/home";
          Restart = "on-failure";
          ExecStartPre = "${pkgs.uutils-coreutils-noprefix}/bin/mkdir -p /home/aki/NAS/home";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      systemd.user.services."sshfs-aki-data" = {
        Unit = {
          Description = "SSHFS Mount for /data";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${pkgs.sshfs}/bin/sshfs -f -o delay_connect,reconnect,ServerAliveInterval=10,ServerAliveCountMax=2,_netdev,user,transform_symlinks,IdentityFile=/home/aki/.ssh/id_ed25519,allow_other,default_permissions,uid=${lib.toString config.users.users.aki.uid},gid=${
            lib.toString config.users.groups.${lib.toString config.users.users.aki.group}.gid
          },exec Aki@toasteruwu.com:/data /home/aki/NAS/data";
          ExecStop = "${pkgs.fuse}/bin/fusermount -u /home/aki/NAS/data";
          Restart = "on-failure";
          ExecStartPre = "${pkgs.uutils-coreutils-noprefix}/bin/mkdir -p /home/aki/NAS/data";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      systemd.user.services."sshfs-aki-backups" = {
        Unit = {
          Description = "SSHFS Mount for /backups";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${pkgs.sshfs}/bin/sshfs -f -o delay_connect,reconnect,ServerAliveInterval=10,ServerAliveCountMax=2,_netdev,user,transform_symlinks,IdentityFile=/home/aki/.ssh/id_ed25519,allow_other,default_permissions,uid=${lib.toString config.users.users.aki.uid},gid=${
            lib.toString config.users.groups.${lib.toString config.users.users.aki.group}.gid
          },exec Aki@toasteruwu.com:/backups /home/aki/NAS/backups";
          ExecStop = "${pkgs.fuse}/bin/fusermount -u /home/aki/NAS/backups";
          Restart = "on-failure";
          ExecStartPre = "${pkgs.uutils-coreutils-noprefix}/bin/mkdir -p /home/aki/NAS/backups";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      systemd.user.services."sshfs-aki-web" = {
        Unit = {
          Description = "SSHFS Mount for /web";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${pkgs.sshfs}/bin/sshfs -f -o delay_connect,reconnect,ServerAliveInterval=10,ServerAliveCountMax=2,_netdev,user,transform_symlinks,IdentityFile=/home/aki/.ssh/id_ed25519,allow_other,default_permissions,uid=${lib.toString config.users.users.aki.uid},gid=${
            lib.toString config.users.groups.${lib.toString config.users.users.aki.group}.gid
          },exec Aki@toasteruwu.com:/web /home/aki/NAS/web";
          ExecStop = "${pkgs.fuse}/bin/fusermount -u /home/aki/NAS/web";
          Restart = "on-failure";
          ExecStartPre = "${pkgs.uutils-coreutils-noprefix}/bin/mkdir -p /home/aki/NAS/web";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      systemd.user.services."sshfs-aki-docker" = {
        Unit = {
          Description = "SSHFS Mount for /docker";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${pkgs.sshfs}/bin/sshfs -f -o delay_connect,reconnect,ServerAliveInterval=10,ServerAliveCountMax=2,_netdev,user,transform_symlinks,IdentityFile=/home/aki/.ssh/id_ed25519,allow_other,default_permissions,uid=${lib.toString config.users.users.aki.uid},gid=${
            lib.toString config.users.groups.${lib.toString config.users.users.aki.group}.gid
          },exec Aki@toasteruwu.com:/docker /home/aki/NAS/docker";
          ExecStop = "${pkgs.fuse}/bin/fusermount -u /home/aki/NAS/docker";
          Restart = "on-failure";
          ExecStartPre = "${pkgs.uutils-coreutils-noprefix}/bin/mkdir -p /home/aki/NAS/docker";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.services."mprisence" = {
        Unit = {
          Description = "Run my favorite all in one Discord Rich Presence Music bridge";
        };
        Service = {
          ExecStart = "${pkgs.mprisence}/bin/mprisence";
          Type = "simple";
          Restart = "always";
          RestartSec = 10;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      xdg.mimeApps = {
        enable = true;
        associations.added = {
          "application/x-extension-htm" = "firefox.desktop";
          "application/x-extension-html" = "firefox.desktop";
          "application/x-extension-shtml" = "firefox.desktop";
          "application/x-extension-xht" = "firefox.desktop";
          "application/x-extension-xhtml" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "text/html" = "firefox.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "model/stl" = "OrcaSlicer.desktop";
          "model/3mf" = "OrcaSlicer.desktop";
          "text/x.gcode" = "OrcaSlicer.desktop";
          "application/x-shellscript" = "code.desktop";
          "application/vhd.microsoft.portable-executable" = "wine.desktop";
        };
        defaultApplications = {
          "application/x-ms-dos-executable" = "wine.desktop";
          "application/x-msi" = "wine.desktop";
          "application/x-ms-shortcut" = "wine.desktop";
          "application/x-bat" = "wine.desktop";
          "application/x-mswinurl" = "wine.desktop";
          "application/vhd.microsoft.portable-executable" = "wine.desktop";
          "video/mp4" = "vlc.desktop";
          "video/x-matroska" = "vlc.desktop";
          "application/x-extension-htm" = "firefox.desktop";
          "application/x-extension-html" = "firefox.desktop";
          "application/x-extension-shtml" = "firefox.desktop";
          "application/x-extension-xht" = "firefox.desktop";
          "application/x-extension-xhtml" = "firefox.desktop";
          "text/html" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "model/stl" = "OrcaSlicer.desktop";
          "model/3mf" = "OrcaSlicer.desktop";
          "text/x.gcode" = "OrcaSlicer.desktop";
          "image/svg+xml" = "code.desktop";
          "application/json" = "code.desktop";
          "application/xml" = "code.desktop";
          "application/yaml" = "code.desktop";
          "application/toml" = "code.desktop";
          "application/x-shellscript" = "code.desktop";
          "text/x-python" = "code.desktop";
          "text/rust" = "code.desktop";
          "text/javascript" = "code.desktop";
          "text/css" = "code.desktop";
          "text/x-cmake" = "code.desktop";
          "text/x-c++src" = "code.desktop";
          "text/x-c++hdr" = "code.desktop";
          "text/x-systemd-unit" = "code.desktop";
          "text/markdown" = "code.desktop";
          "text/plain" = "code.desktop";
          "x-scheme-handler/bitwarden" = "Bitwarden.desktop";
          "x-scheme-handler/beatsaver" = "BeatSaberModManager-url-beatsaver.desktop";
          "x-scheme-handler/bsplaylist" = "BeatSaberModManager-url-bsplaylist.desktop";
          "x-scheme-handler/modelsaber" = "BeatSaberModManager-url-modelsaber.desktop";
          "application/x-modrinth-modpack+zip" = "org.prismlauncher.PrismLauncher.desktop";
          "x-scheme-handler/curseforge" = "org.prismlauncher.PrismLauncher.desktop";
        };
      };

      catppuccin.enable = true;
      catppuccin.autoEnable = true;
      catppuccin.flavor = "mocha";
      catppuccin.accent = "pink";

      gtk = {
        enable = true;
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
        theme = {
          name = "catppuccin-mocha-pink-standard";
          package = (
            pkgs.catppuccin-gtk.override {
              variant = "mocha";
              accents = [ "pink" ];
            }
          );
        };
        gtk4.theme = config.home-manager.users.aki.gtk.theme;
      };

      qt = {
        enable = true;
        style.name = "kvantum";
      };

      programs = {
        nixcord = {
          enable = true;

          discord.vencord.enable = false;
          discord.equicord.enable = true;

          config = {
            themeLinks = [ "https://catppuccin.github.io/discord/dist/catppuccin-mocha-pink.theme.css" ];
            enabledThemeLinks = [ "https://catppuccin.github.io/discord/dist/catppuccin-mocha-pink.theme.css" ];
            frameless = true;

            plugins = {
              altKrispSwitch.enable = true;
              anonymiseFileNames.enable = true;
              betterActivities.enable = true;
              betterCommands = {
                enable = true;
                autoFillArguments = false;
              };
              blurNsfw.enable = true;
              callTimer.enable = true;
              characterCounter.enable = true;
              clearUrls.enable = true;
              clickableRoles.enable = true;
              contentWarning = {
                enable = true;
                triggerWords = [
                  "rape"
                  "sexual assault"
                ];
              };
              copyFileContents.enable = true;
              copyUserUrls.enable = true;
              disableCallIdle.enable = true;
              dontRoundMyTimestamps.enable = true;
              exportMessages = {
                enable = true;
                exportContacts = true;
              };
              expressionCloner.enable = true;
              fakeNitro.enable = true;
              favoriteEmojiFirst.enable = true;
              findReply.enable = true;
              fixFileExtensions.enable = true;
              fixImagesQuality.enable = true;
              fixSpotifyEmbeds.enable = true;
              fixYoutubeEmbeds.enable = true;
              followVoiceUser.enable = true;
              forceOwnerCrown.enable = true;
              betterForwards.enable = true;
              friendshipRanks.enable = true;
              gameActivityToggle.enable = true;
              gifCollections.enable = true;
              greetStickerPicker.enable = true;
              guildPickerDumper.enable = true;
              homeTyping.enable = true;
              iLoveSpam.enable = true;
              imageZoom.enable = true;
              implicitRelationships.enable = true;
              jumpTo.enable = true;
              memberCount.enable = true;
              messageLinkEmbeds.enable = true;
              messageLoggerEnhanced.enable = true;
              mutualGroupDms.enable = true;
              newPluginsManager.enable = true;
              noF1.enable = true;
              noNitroUpsell.enable = true;
              openInApp = {
                enable = true;
                epic = false;
                itunes = false;
                spotify = false;
                steam = true;
                tidal = false;
                vrcx = false;
              };
              permissionsViewer.enable = true;
              petpet.enable = true;
              pictureInPicture.enable = true;
              pinDms = {
                enable = true;
                userBasedCategoryList = {
                  "235416194293694466" = [
                    {
                      id = "xzt0czhin2";
                      name = "Special";
                      color = 13601515;
                      collapsed = false;
                      channels = [
                        "1361859492563779604"
                        "1363341770112372886"
                        "1534398875929149500"
                        "1354257168563703810"
                      ];
                    }
                  ];
                };
              };
              quoter.enable = true;
              relationshipNotifier.enable = true;
              replaceGoogleSearch = {
                enable = true;
                replacementEngine = "custom";
                customEngineUrl = "https://duckduckgo.com/?q=";
                customEngineName = "DuckDuckGo";
              };
              reverseImageSearch.enable = true;
              richMagnetLinks.enable = true;
              saveFavoriteGifs.enable = true;
              scheduledMessages.enable = true;
              searchFix.enable = true;
              sendTimestamps.enable = true;
              silentMessageToggle.enable = true;
              splitLargeMessages.enable = true;
              timezones = {
                enable = true;
                twentyFourHourFormat = true;
                askedTimezone = true;
              };
              voiceChatDoubleClick.enable = true;
              voiceDownload.enable = true;
              voiceMessages.enable = true;
              voiceRejoin.enable = true;
              volumeBooster.enable = true;
              whoReacted.enable = true;
              whosWatching.enable = true;
              youtubeAdblock.enable = true;
            };
          };
        };
        fastfetch = {
          enable = true;
        };
        hyfetch = {
          enable = true;
          settings = {
            preset = "transgender";
            mode = "rgb";
            light_dark = "dark";
            lightness = 0.65;
            color_align = {
              mode = "horizontal";
              custom_colors = [ ];
              fore_back = null;
            };
            backend = "fastfetch";
            distro = null;
            pride_month_shown = [ ];
            pride_month_disable = false;
          };
        };
        fish = {
          enable = true;
          interactiveShellInit = "hyfetch";
          shellAliases = {
            "ls" = "eza";
          };
        };
        starship = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            directory = {
              truncation_length = 12;
              truncate_to_repo = false;
              truncation_symbol = "…/";
            };
          };
        };
        eza = {
          enable = true;
          enableFishIntegration = true;
        };
        zoxide = {
          enable = true;
          enableFishIntegration = true;
          options = [ "--cmd cd" ];
        };
        zellij = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            show_startup_tips = false;
          };
          exitShellOnExit = true;
        };
        tealdeer = {
          enable = true;
          settings.updates = {
            auto_update = true;
            auto_update_interval_hours = 24;
          };
        };
        bat.enable = true;
        ripgrep.enable = true;
        ripgrep-all.enable = true;
        fd.enable = true;
        btop.enable = true;
        bottom.enable = true;
        gitui.enable = true;
        tirith = {
          enable = true;
          enableFishIntegration = true;
        };
        ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "*" = {
              User = "aki";
              StrictHostKeyChecking = "accept-new";
            };

            hiltrud = {
              HostName = "192.168.178.34";
              User = "mks";
            };

            discord-bots = {
              HostName = "192.168.178.10";
            };

            discord-bots-root = {
              HostName = "192.168.178.10";
              User = "root";
            };

            mongo-db = {
              HostName = "192.168.178.9";
            };

            smart-home = {
              HostName = "192.168.178.6";
            };

            tor-node = {
              HostName = "192.168.178.18";
            };

            xen-orchestra = {
              HostName = "192.168.178.5";
            };

            gutruhn = {
              HostName = "192.168.178.3";
            };

            hedwig = {
              HostName = "192.168.178.4";
              User = "root";
            };

            nixos-homeserver = {
              HostName = "192.168.178.11";
              User = "root";
            };

            barbara = {
              HostName = "192.168.178.100";
            };

            rouge = {
              HostName = "192.168.178.178";
            };
          };
        };
      };
      xdg.configFile."supersonic/themes/catppuccin-mocha-pink.toml".source = ../assets/supersonic/catppuccin-mocha-pink.toml;
      xdg.configFile."supersonic/config.toml".source = ../assets/supersonic/config.toml;
    };
  };
}
