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
    arion = {
      backend = "docker";
    };
  };
  users.users.aki.extraGroups = [ "docker" ];

  virtualisation.arion.projects = {
    watchtower = {
      settings.services = {
        watchtower.service = {
          stop_grace_period = "5m";
          container_name = "watchtower";
          image = "containrrr/watchtower:latest";
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/etc/localtime:/etc/localtime:ro"
          ];
          environment = {
            WATCHTOWER_CLEANUP = "true";
            WATCHTOWER_REMOVE_VOLUMES = "true";
            WATCHTOWER_SCHEDULE = "0 0 8 * * 3"; # every Wednesday at 8am
          };
          restart = "unless-stopped";
        };
      };
    };
    tdarr-node = {
      settings.services = {
        tdarr-node.service = {
          stop_grace_period = "5m";
          container_name = "tdarr-node";
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
          env_file = [ config.age.secrets."tdarr-apiKey".path ];
          restart = "unless-stopped";
        };
      };
    };
  };
  systemd.services.arion-tdarr-node = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "aki";
      Group = "users";
    };
  };

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
