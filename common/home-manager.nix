{
  pkgs,
  config,
  catppuccin,
  lib,
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

    sharedModules = [ catppuccin.homeModules.catppuccin ];

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
      };

      programs = {
        ghostty = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            confirm-close-surface = false;
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
          matchBlocks = {
            "*" = {
              user = "aki";
              extraOptions = {
                StrictHostKeyChecking = "accept-new";
              };
            };

            hiltrud = {
              hostname = "192.168.178.167";
              user = "mks";
            };

            discord-bots = {
              hostname = "192.168.178.10";
            };

            discord-bots-root = {
              hostname = "192.168.178.10";
              user = "root";
            };

            mongo-db = {
              hostname = "192.168.178.9";
            };

            smart-home = {
              hostname = "192.168.178.6";
            };

            tor-node = {
              hostname = "192.168.178.18";
            };

            xen-orchestra = {
              hostname = "192.168.178.5";
            };

            gutruhn = {
              hostname = "192.168.178.3";
            };

            hedwig = {
              hostname = "192.168.178.4";
              user = "root";
            };

            nixos-homeserver = {
              hostname = "192.168.178.11";
              user = "root";
            };

            barbara = {
              hostname = "192.168.178.100";
            };

            rouge = {
              hostname = "192.168.178.178";
            };
          };
        };
      };
      xdg.configFile."autostart/vesktop.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Vesktop
        Comment=Vesktop autostart script
        Exec=vesktop
        StartupNotify=false
        Terminal=false
      '';
      xdg.configFile."autostart/openrgb.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=OpenRGB
        Comment=OpenRGB autostart script
        Exec=openrgb --startminimized --profile Pink
        StartupNotify=false
        Terminal=false
      '';
      xdg.configFile."supersonic/themes/catppuccin-mocha-pink.toml".source = ../assets/supersonic/catppuccin-mocha-pink.toml;
      xdg.configFile."supersonic/config.toml".source = ../assets/supersonic/config.toml;
    };
  };
}
