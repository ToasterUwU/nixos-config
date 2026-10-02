# The speech, voice and embedding models EliteIntel loads from beside its jar.
#
# Upstream keeps them in Git LFS, so the source tarball only carries pointer
# files for them. Each pointer is replaced by the same file fetched from where
# it is published, pinned by the pointer's oid (the sha256 of the content).
# The package checks every pointer against its pin, so a release that changes
# a model fails to build until its pin here is updated.
{
  fetchurl,
  fetchzip,
  src,
}:

let
  huggingFace = repo: rev: file: oid: {
    inherit oid;
    file = fetchurl {
      url = "https://huggingface.co/${repo}/resolve/${rev}/${file}";
      hash = "sha256:${oid}";
    };
  };

  parakeet = huggingFace "csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8" "2bda32ec70b097a55adaa07d9a7173915b43cc78";
  supertonic = huggingFace "csukuangfj2/sherpa-onnx-supertonic-3-tts-int8-2026-05-11" "cca5a0e6c96e1d2c720986bf7e75fcc81dee3ae4";
  e5 = huggingFace "Xenova/multilingual-e5-small" "761b726dd34fb83930e26aab4e9ac3899aa1fa78";

  # EliteIntel ships its own 53-speaker build of kokoro-multi-lang-v1_0 (the
  # published one has 54, and the app hardcodes speaker ids), so these two come
  # from upstream's LFS storage.
  kokoro = file: oid: {
    inherit oid;
    file = fetchurl {
      url = "https://github.com/SudoKrondor/EliteIntel/raw/${src.rev}/distribution/tts/kokoro-multi-lang-v1_0/${file}";
      hash = "sha256:${oid}";
    };
  };
in
{
  # Path under distribution/ -> the pinned file replacing its LFS pointer.
  files = {
    "parakeet/encoder.int8.onnx" =
      parakeet "encoder.int8.onnx" "acfc2b4456377e15d04f0243af540b7fe7c992f8d898d751cf134c3a55fd2247";
    "parakeet/decoder.int8.onnx" =
      parakeet "decoder.int8.onnx" "179e50c43d1a9de79c8a24149a2f9bac6eb5981823f2a2ed88d655b24248db4e";
    "parakeet/joiner.int8.onnx" =
      parakeet "joiner.int8.onnx" "3164c13fc2821009440d20fcb5fdc78bff28b4db2f8d0f0b329101719c0948b3";

    "tts/kokoro-multi-lang-v1_0/model.onnx" =
      kokoro "model.onnx" "c436dc6a842b62aba06af67e40bafcfb9c60ac3af895358f1974ad9a7f7c026b";
    "tts/kokoro-multi-lang-v1_0/voices.bin" =
      kokoro "voices.bin" "8a77c0d397026208d22211f37670b5b3b11e03f190756b25a1d24041fced82a9";

    "tts/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/duration_predictor.int8.onnx" =
      supertonic "duration_predictor.int8.onnx" "c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db";
    "tts/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/text_encoder.int8.onnx" =
      supertonic "text_encoder.int8.onnx" "c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff";
    "tts/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/unicode_indexer.bin" =
      supertonic "unicode_indexer.bin" "8402ca48e5189a8950138580b0fff64db6f072f24ac07cd54ba8b2fbb9883b30";
    "tts/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/vector_estimator.int8.onnx" =
      supertonic "vector_estimator.int8.onnx" "20cd86fa5c6effedfda0e7cffe5b0569ca401c440a0c3a1d72bf39286c0db3fd";
    "tts/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/vocoder.int8.onnx" =
      supertonic "vocoder.int8.onnx" "e923d60f53f95eb1ce235f1dc33ec56d9c057823c96fa6f8acf98f32b0da6152";
    "tts/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/voice.bin" =
      supertonic "voice.bin" "67d5209b0ee8ce6c74105ffbe12fe6a7628aea3b4ba2fcb308a4a67938a93ce8";

    "embed/multilingual-e5-small/model_quantized.onnx" =
      e5 "onnx/model_quantized.onnx" "f80102d3f2a1229f387d3c81909990d8945513e347b0eab049f7de3c6f98c193";
    "embed/multilingual-e5-small/tokenizer.json" =
      e5 "tokenizer.json" "0b44a9d7b51c3c62626640cda0e2c2f70fdacdc25bbbd68038369d14ebdf4c39";
  };

  # 355 small files, all LFS pointers upstream; identical to the published model's.
  kokoroEspeakNgData = fetchzip {
    name = "kokoro-multi-lang-v1_0-espeak-ng-data";
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-multi-lang-v1_0.tar.bz2";
    postFetch = ''
      find $out -mindepth 1 -maxdepth 1 ! -name espeak-ng-data -exec rm -r {} +
    '';
    hash = "sha256-GVXiBKBO5CyWuiX0bjX6qAEiKkAL7D16EANV41NkPQQ=";
  };
}
