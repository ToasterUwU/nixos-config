{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.noctalia-w-engine;
  # W Engine keeps its per-output state in pluginDataDir()/data.json and rewrites it in place,
  # so it can't be a read-only symlink. Merge the declared values into it on activation instead.
  dataDir = "${config.xdg.stateHome}/noctalia/plugins/data/tadomika_ari/w-engine";
  declared = pkgs.writeText "w-engine-declared.json" (
    builtins.toJSON {
      current = cfg.screens;
      engine = cfg.engine;
    }
  );
  merge = pkgs.writeShellScript "noctalia-w-engine-merge" ''
    set -eu
    data=${lib.escapeShellArg "${dataDir}/data.json"}
    mkdir -p -m 700 ${lib.escapeShellArg dataDir}
    [ -s "$data" ] || echo '{}' > "$data"
    ${lib.getExe pkgs.jq} --slurpfile decl ${declared} \
      '.current = ((.current // {}) + $decl[0].current) | .defaults.engine = ((.defaults.engine // {}) + $decl[0].engine)' \
      "$data" > "$data.tmp"
    mv "$data.tmp" "$data"
    chmod 600 "$data"
  '';
in
{
  options.programs.noctalia-w-engine = {
    screens = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Wallpaper Engine workshop id to play per output connector.";
      example = {
        DP-1 = "1463724965";
      };
    };

    engine = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          str
        ]);
      default = { };
      description = "Global linux-wallpaperengine playback defaults (W Engine's `defaults.engine`).";
    };
  };

  config = lib.mkIf (cfg.screens != { } || cfg.engine != { }) {
    home.activation.noctaliaWEngine = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${merge}
    '';
  };
}
