{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    # Optional: preload models, see https://ollama.com/library
    loadModels = [
      "qwen2.5-coder:7b"
      "qwen3-coder:30b"
    ];
    package = pkgs.ollama-vulkan;
  };
}
