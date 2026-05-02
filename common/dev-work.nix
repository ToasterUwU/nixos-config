{
  pkgs,
  config,
  nixpkgs,
  nixpkgs-update,
  direnv-instant,
  ...
}:
{
  age.secrets = {
    "aki-nixpkgs-review-github-token" = {
      file = ../secrets/common/aki-nixpkgs-review-github-token.age;
      mode = "700";
      owner = "aki";
      group = "users";
    };
    "aki-nixpkgs-update-github-token" = {
      file = ../secrets/common/aki-nixpkgs-update-github-token.age;
      mode = "700";
      owner = "aki";
      group = "users";
    };
  };

  home-manager = {
    sharedModules = [ direnv-instant.homeModules.direnv-instant ];
    users.aki = {
      programs = {
        git = {
          enable = true;
          package = pkgs.gitFull;

          lfs.enable = true;
          settings = {
            user = {
              name = "ToasterUwU";
              email = "Aki@ToasterUwU.com";
            };

            init.defaultBranch = "main";

            # Thanks Scrumplex for showing me this from Scott! https://www.youtube.com/watch?v=aolI_Rz0ZqY
            rerere.enabled = true;
            core.fsmonitor = true;
          };

          signing.format = "openpgp";
        };

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        direnv-instant = {
          enable = true;
        };

        vscode = {
          enable = true;
          profiles.default = {
            enableUpdateCheck = false;
            userSettings = {
              "catppuccin.accentColor" = "pink";
              "editor.semanticHighlighting.enabled" = true;
              "terminal.integrated.minimumContrastRatio" = 1;
              "window.titleBarStyle" = "custom";
              "workbench.colorTheme" = "Catppuccin Mocha";
              "files.autoSave" = "afterDelay";
              "git.enableSmartCommit" = true;
              "git.confirmSync" = false;
              "nix.enableLanguageServer" = true;
              "nix.serverPath" = "nixd";
              "nix.serverSettings" = {
                "nixd" = {
                  "formatting" = {
                    "command" = [ "nixfmt" ];
                  };
                };
              };
              "nix.formatterPath" = "nixfmt";
              "editor.fontFamily" = "FiraCode Nerd Font Mono";
              "editor.fontLigatures" = true;
              "[python]" = {
                "editor.defaultFormatter" = "charliermarsh.ruff";
              };
              "python.analysis.typeCheckingMode" = "standard";
              "lldb.suppressUpdateNotifications" = true;
              "chat.disableAIFeatures" = true;
              "diffEditor.ignoreTrimWhitespace" = false;
              "[json]" = {
                "editor.defaultFormatter" = "vscode.json-language-features";
              };
            };
          };
          package = pkgs.vscode.fhsWithPackages (
            ps: with ps; [
              nodejs_22
              nixd
              act
            ]
          );
        };
      };
    };
  };

  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

  users.users.aki = {
    packages = with pkgs; [
      nixfmt
      (writeScriptBin "nixpkgs-review" ''
        #!/usr/bin/env bash

        export GITHUB_TOKEN=$(cat ${config.age.secrets."aki-nixpkgs-review-github-token".path})
        exec ${pkgs.nixpkgs-review}/bin/nixpkgs-review "$@"
      '')
      (writeScriptBin "nixpkgs-update" ''
        #!/usr/bin/env bash

        export GITHUB_TOKEN=$(cat ${config.age.secrets."aki-nixpkgs-update-github-token".path})
        exec ${nixpkgs-update.packages.x86_64-linux.default}/bin/nixpkgs-update "$@"
      '')

      openscad-lsp
      clang-tools

      zlib
      gcc
      glibc
      binutils
      gnumake
      pkg-config
      openssl.dev
      systemd.dev
      gtk3.dev

      rustc
      rust-analyzer

      nodejs

      python3

      renderdoc
    ];
  };
}
