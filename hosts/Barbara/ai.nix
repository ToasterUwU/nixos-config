{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    # Optional: preload models, see https://ollama.com/library
    loadModels = [
      "qwen2.5-coder:7b"
      "qwen3-coder:30b"
      "gemma4:31b"
    ];
    package = pkgs.ollama-vulkan;
    environmentVariables = {
      GGML_VK_VISIBLE_DEVICES = "0";
    };
  };
}
