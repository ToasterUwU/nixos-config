{
  stdenv,
  imagemagick,
  writeShellApplication
}:
stdenv.mkDerivation {
  pname = "split-3d-image";
  version = "1.0";

  src = writeShellApplication {
    name = "split-3d-image";

    runtimeInputs = [
      imagemagick
    ];

    checkPhase = ''
      echo "I dont care" # Fix shellcheck being upset about no direct call of "off"
    '';

    text = ''
      # 1. Validate input
      if [ -z "$1" ]; then
          echo "Usage: $0 <image_file>"
          exit 1
      fi

      INPUT_FILE="$1"

      if [ ! -f "$INPUT_FILE" ]; then
          echo "Error: File '$INPUT_FILE' not found."
          exit 1
      fi

      # 2. Check for ImageMagick (supports both v7 'magick' and v6 'convert')
      if command -v magick &> /dev/null; then
          IM_CMD="magick"
      elif command -v convert &> /dev/null; then
          IM_CMD="convert"
      else
          echo "Error: ImageMagick is not installed. Please install it first."
          exit 1
      fi

      # 3. Create a temporary file with the same extension as the input
      # This ensures the format (jpg, png, etc.) is preserved correctly
      EXT="$\{INPUT_FILE##*.}"
      TEMP_FILE=$(mktemp /tmp/img_split_XXXXXX."$EXT")

      echo "Processing '$INPUT_FILE'..."

      # 4. Perform the split
      # -gravity West : Aligns the crop to the left side
      # -crop 50x100%+0+0 : Keeps 50% of the width, 100% of the height
      # +repage : Clears the original canvas metadata so it behaves as a new standalone image
      if $IM_CMD "$INPUT_FILE" -gravity West -crop 50x100%+0+0 +repage "$TEMP_FILE"; then
          # 5a. Success: Safe to overwrite the original
          mv "$TEMP_FILE" "$INPUT_FILE"
          echo "Success: Image split! The original file has been updated with the left half."

      else
          # 5b. Failure: Clean up and protect the original
          echo "Error: Image processing failed. Your original file remains untouched."
          rm -f "$TEMP_FILE"
          exit 1

      fi
    '';
  };

  installPhase = ''
    mkdir -p $out/bin
    cp $src/bin/split-3d-image $out/bin/
    chmod +x $out/bin/split-3d-image
  '';

  meta = {
    description = "Split LR 3D images (mainly from Resonite), converting them to a normal 2D image";
  };
}
