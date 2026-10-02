#!@runtimeShell@
# Launcher for EliteIntel, standing in for upstream's install4j launcher.

# EliteIntel writes its logs to ./logs, so run it from a writable directory.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/elite-intel"
mkdir -p "$state_dir"
cd "$state_dir" || exit 1

# On Linux the app defaults to reading the game's journal and bindings from
# these two links, which upstream's launcher (re)creates on every start by
# looking for Elite Dangerous (Steam app 359320) in the Proton prefix. Same
# here; never fail the launch over it.
link_dir="$HOME/.var/app/elite.intel.app"

link_game_folders() {
  local steam library prefix bindings journal
  local -a libraries=()

  for steam in \
    "$HOME/.steam/steam" \
    "$HOME/.local/share/Steam" \
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" \
    "$HOME/snap/steam/common/.local/share/Steam"; do
    [ -d "$steam/steamapps" ] || continue
    libraries+=("$steam")
    # The game may live in another Steam library folder.
    if [ -f "$steam/steamapps/libraryfolders.vdf" ]; then
      while IFS= read -r library; do
        libraries+=("$library")
      done < <(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$steam/steamapps/libraryfolders.vdf")
    fi
  done

  for library in "${libraries[@]}"; do
    prefix="$library/steamapps/compatdata/359320/pfx/drive_c/users/steamuser"
    [ -d "$prefix" ] || continue

    bindings=$(find "$prefix/AppData/Local" -type d -path "*/Frontier Developments/Elite Dangerous/Options/Bindings" 2>/dev/null | head -n1)
    journal=$(find "$prefix/Saved Games" -type d -path "*/Frontier Developments/Elite Dangerous" 2>/dev/null | head -n1)

    if [ -n "$bindings" ] && [ -n "$journal" ]; then
      mkdir -p "$link_dir"
      ln -sfn "$bindings" "$link_dir/ed-bindings"
      ln -sfn "$journal" "$link_dir/ed-journal"
      return 0
    fi
  done
  return 1
}

if [ ! -d "$link_dir/ed-bindings" ] || [ ! -d "$link_dir/ed-journal" ]; then
  link_game_folders || true
fi

exec @java@ @javaFlags@ -jar @jar@ "$@"
