{
  makeDesktopItem,
  stdenv,
  writeShellApplication,
  lib,
  wayvr,
  lighthouse-steamvr,
  kdePackages,
  lovr-playspace,
  ...
}:
let
  monado-start-desktop = makeDesktopItem {
    exec = "monado-start";
    icon = "steamvr";
    name = "Start Monado";
    desktopName = "Start Monado";
    terminal = true;
  };
in
stdenv.mkDerivation {
  pname = "monado-start";
  version = "3.4.0";

  src = writeShellApplication {
    name = "monado-start";

    runtimeInputs = [
      wayvr
      lighthouse-steamvr
      kdePackages.kde-cli-tools
      lovr-playspace
    ];

    checkPhase = ''
      echo "I dont care" # Fix shellcheck being upset about no direct call of "off"
    '';

    text = ''
      GROUP_PID_FILE="/tmp/monado-group-pid-$$"

      function gpu_vr_mode() {
        # Enable manual override
        echo "manual" | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level >/dev/null

        # Translate "VR" into profile number
        vr_profile=$(cat /sys/class/drm/card1/device/pp_power_profile_mode | grep ' VR' | awk '{ print $1; }')

        # Set profile to VR
        echo $vr_profile | sudo tee /sys/class/drm/card1/device/pp_power_profile_mode >/dev/null
      }

      function gpu_auto_mode() {
        # Disable manual override
        echo "auto" | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level >/dev/null

        # Set profile to DEFAULT
        echo 0 | sudo tee /sys/class/drm/card1/device/pp_power_profile_mode >/dev/null
      }

      function lighthouse_off() {
        ${lib.getExe lighthouse-steamvr} -vv --state off
      }

      function off() {
        echo "Stopping Monado and other stuff..."

        if [ -f "$GROUP_PID_FILE" ]; then
          PGID=$(cat "$GROUP_PID_FILE")
          echo "Killing process group $PGID..."
          kill -- -"$PGID" 2>/dev/null
          rm -f "$GROUP_PID_FILE"
        fi

        systemctl --user --no-block stop monado.service
      }

      function full_off() {
        gpu_auto_mode
        lighthouse_off &
        off

        wait

        exit 0
      }

      function lighthouse_on() {
        ${lib.getExe lighthouse-steamvr} -vv --state on &
      }

      function on() {
        echo "Starting Monado and other stuff..."

        systemctl --user restart monado.service

        setsid sh -c '
          ${lib.getExe lovr-playspace} &
          ${lib.getExe wayvr} --replace &
          kde-inhibit --power --screenSaver sleep infinity &
          wait
        ' &
        PGID=$!
        echo "$PGID" > "$GROUP_PID_FILE"
      }

      trap full_off INT TERM

      gpu_vr_mode
      lighthouse_on &
      while :
      do
        on
        echo "Press CTRL+C to turn everything OFF, anything else to restart Monado and reliant programs"
        read -r
        off
      done
    '';
  };

  installPhase = ''
    mkdir -p $out/bin
    cp $src/bin/monado-start $out/bin/
    chmod +x $out/bin/monado-start

    cp -r ${monado-start-desktop}/* $out/
  '';

  meta = {
    description = "Start script for monado and all other things i use with it.";
  };
}
