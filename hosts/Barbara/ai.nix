{
  pkgs,
  lib,
  config,
  lmstudio,
  hermes-agent,
  ...
}:
let
  hermesEnvFile = config.age.secrets."hermes-env".path;
in
{
  nixpkgs.overlays = [ lmstudio.overlays.default ];

  environment.systemPackages = [ pkgs.lmstudio ];

  # Hermes runs local models with a llama.cpp build it downloads itself (generic Linux binaries, started through nix-ld).
  # Without libvulkan on the nix-ld path its Vulkan backend silently fails to load and everything runs on the CPU.
  programs.nix-ld.libraries = [ pkgs.vulkan-loader ];

  age.secrets."hermes-env" = {
    file = ../../secrets/common/hermes-env.age;
    owner = "aki";
    group = "users";
    mode = "600";
  };

  home-manager = {
    sharedModules = [ hermes-agent.homeManagerModules.default ];

    users.aki =
      { config, ... }:
      {
        systemd.user.services.hermes-agent.Service = {
          Environment = [
            # Hide every Vulkan device except the RX 7900 XT (PCI 1002:744c) from the llama.cpp server the gateway starts.
            "MESA_VK_DEVICE_SELECT=1002:744c"
            "MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=1"
          ];
          ExecStartPre = "-${lib.getExe config.services.hermes-agent.package} pm install llamacpp-vulkan";
        };

        programs.hermes-agent = {
          enable = true;
          desktop.enable = true;
        };

        services.hermes-agent = {
          enable = true;
          gateway.enable = true;

          environmentFiles = [ hermesEnvFile ];
          extraPackages = with pkgs; [
            curl
            jq
          ];

          settings = {
            local_runtime = {
              enabled = true;
              backend = "vulkan";
            };
            model = {
              provider = "llamacpp";
              default = "gemma-4-26B-A4B-it-QAT-Q4_0";
            };
          };
        };
      };
  };
}
