{
  lib,
  fetchFromGitHub,
  fetchurl,
  sherpa-onnx,
  jdk21_headless,
}:

# EliteIntel pins sherpa-onnx 1.13.8 and ships a prebuilt JNI library plus the
# matching Java API jar. nixpkgs only carries 1.13.3 without Java support, so
# build both from source here.
#
# TODO: upstream as a `javaSupport` flag (and version bump) on nixpkgs'
# sherpa-onnx, then drop this file.
let
  # Pre-fetched dependencies for cmake FetchContent, as in nixpkgs' sherpa-onnx,
  # updated for the pins of 1.13.8.
  cache = [
    {
      name = "espeak-ng-ed530aa113046142eb5115cf2fc9157854d0ffe1.zip";
      src = fetchurl {
        url = "https://github.com/csukuangfj/espeak-ng/archive/ed530aa113046142eb5115cf2fc9157854d0ffe1.zip";
        hash = "sha256-5OJiy+NPf+IfkfG6M5fyco4fMOr7rnhT8rdTqe0T8N0=";
      };
    }
    {
      name = "kaldi-native-fbank-1.22.3.tar.gz";
      src = fetchurl {
        url = "https://github.com/csukuangfj/kaldi-native-fbank/archive/refs/tags/v1.22.3.tar.gz";
        hash = "sha256-kXbMZvx84e34XPNVsG4yDFfbYpffdCd/V1GDRoiTz2E=";
      };
    }
    {
      name = "simple-sentencepiece-0.7.tar.gz";
      src = fetchurl {
        url = "https://github.com/pkufool/simple-sentencepiece/archive/refs/tags/v0.7.tar.gz";
        hash = "sha256-F0ioIgYKNbqp9mCfhO/I61TcDnS57OPYI2e3EZ/cda8=";
      };
    }
    {
      name = "kaldifst-1.8.0.tar.gz";
      src = fetchurl {
        url = "https://github.com/k2-fsa/kaldifst/archive/refs/tags/v1.8.0.tar.gz";
        hash = "sha256-PyR7flokCQcSAvXivGIABg9mcowKNEPAOSOtJyPgQLM=";
      };
    }
    {
      name = "kaldi-decoder-0.3.0.tar.gz";
      src = fetchurl {
        url = "https://github.com/k2-fsa/kaldi-decoder/archive/refs/tags/v0.3.0.tar.gz";
        hash = "sha256-ufNM+0/TsTRBAO6tee9NN6oVliJ0ueMFbeNFAh92obA=";
      };
    }
    {
      name = "cargs-1.0.3.tar.gz";
      src = fetchurl {
        url = "https://github.com/likle/cargs/archive/refs/tags/v1.0.3.tar.gz";
        hash = "sha256-3bolvTXpxsdbxwbBJgAbjOjghNQO83BQ5qppY+g264s=";
      };
    }
    {
      name = "piper-phonemize-f3ff95afc03640bc1399e113e83361192a2fafb4.zip";
      src = fetchurl {
        url = "https://github.com/csukuangfj/piper-phonemize/archive/f3ff95afc03640bc1399e113e83361192a2fafb4.zip";
        hash = "sha256-2cyk4r3H1t2N/7lqRmgoPb0/d6nBlKPlMMHo66lAal0=";
      };
    }
    {
      name = "openfst-1.8.5-2026-07-09.tar.gz";
      src = fetchurl {
        url = "https://github.com/csukuangfj/openfst/archive/refs/tags/v1.8.5-2026-07-09.tar.gz";
        hash = "sha256-L/cSoylS/LAdNREhpryMz0/cayqgbOjfKzCV3t1RjA4=";
      };
    }
    {
      name = "hclust-cpp-2026-02-25.tar.gz";
      src = fetchurl {
        url = "https://github.com/csukuangfj/hclust-cpp/archive/refs/tags/2026-02-25.tar.gz";
        hash = "sha256-jxTgJMcJ1zr7QK5pyyLeS3Pbpny85A8uUYgT2oE5q1Y=";
      };
    }
  ];
in
(sherpa-onnx.override {
  pythonSupport = false;
  websocketSupport = false;
}).overrideAttrs
  (
    finalAttrs: previousAttrs: {
      pname = "sherpa-onnx-java";
      version = "1.13.8";

      src = fetchFromGitHub {
        owner = "k2-fsa";
        repo = "sherpa-onnx";
        tag = "v${finalAttrs.version}";
        hash = "sha256-yAkjeRJXSiGW7Pr6cmHKUeYiWZyd88raEMdaJvYhQLM=";
      };

      nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [ jdk21_headless ];

      # The JNI CMakeLists reads the JDK headers from $JAVA_HOME.
      env = (previousAttrs.env or { }) // {
        JAVA_HOME = jdk21_headless.home;
      };

      preConfigure = ''
        ${lib.concatMapStringsSep "\n" (s: "cp ${s.src} ./${s.name}") cache}
      '';

      cmakeFlags = previousAttrs.cmakeFlags ++ [
        (lib.cmakeBool "SHERPA_ONNX_ENABLE_JNI" true)
      ];

      postBuild = (previousAttrs.postBuild or "") + ''
        mkdir -p java-classes
        javac -encoding UTF-8 --release 8 -nowarn -d java-classes \
          $(find ../sherpa-onnx/java-api/src/main/java -name '*.java')
        jar cf sherpa-onnx.jar -C java-classes .
      '';

      postInstall = (previousAttrs.postInstall or "") + ''
        install -Dm644 sherpa-onnx.jar $out/share/java/sherpa-onnx.jar
      '';

      meta = removeAttrs previousAttrs.meta [ "mainProgram" ] // {
        description = "Java bindings (JNI library and API jar) for sherpa-onnx";
      };
    }
  )
