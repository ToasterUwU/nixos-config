{
  pkgs,
  config,
  lib,
  ...
}:
{
  age.secrets = {
    "tdarr-apiKey" = {
      file = ../secrets/common/tdarr-apiKey.age;
      mode = "700";
      owner = "aki";
      group = "users";
    };
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    docker = {
      enable = true;
      liveRestore = false;
    };
    oci-containers = {
      backend = "docker";
    };
  };
  users.users.aki.extraGroups = [ "docker" ];

  virtualisation.oci-containers.containers = {
    watchtower = {
      image = "nickfedor/watchtower:latest";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        WATCHTOWER_CLEANUP = "true";
        WATCHTOWER_REMOVE_VOLUMES = "true";
        WATCHTOWER_SCHEDULE = "0 0 8 * * 3"; # every Wednesday at 8am
      };
      # equivalent of composes stop_grace_period = 5m
      extraOptions = [ "--stop-timeout=300" ];
    };
    tdarr-node = {
      image = "ghcr.io/haveagitgat/tdarr_node:latest";
      volumes = [
        "/home/aki/Tdarr/configs:/app/configs"
        "/home/aki/Tdarr/logs:/app/logs"
        "/home/aki/NAS/data/Video Station:/media"
        "/home/aki/Tdarr/transcode_cache:/temp"
      ];
      ports = [ "8268:8268" ];
      environment = {
        nodeName = config.networking.hostName;
        serverIP = "192.168.178.11";
        serverPort = "8266";
        inContainer = "true";
        TZ = "Europe/Berlin";
        PUID = lib.toString config.users.users.aki.uid;
        PGID = lib.toString config.users.groups.${lib.toString config.users.users.aki.group}.gid;
      };
      environmentFiles = [ config.age.secrets."tdarr-apiKey".path ];
      # equivalent of composes stop_grace_period = 5m
      extraOptions = [ "--stop-timeout=300" ];
    };
  };

  # give the containers enough time to shut down gracefully (see --stop-timeout above)
  systemd.services.docker-watchtower.serviceConfig.TimeoutStopSec = lib.mkForce 330;
  systemd.services.docker-tdarr-node.serviceConfig.TimeoutStopSec = lib.mkForce 330;

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    lazydocker # status of containers in the terminal
    docker-compose # start group of containers

    gnome-boxes

    virtiofsd
  ];
}
