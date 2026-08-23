let
  aki = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMV93pUyoE8y3oFfFrgPaaObAP7J9O7aChY1gIWKKTMS";

  Barbara = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEivYBAuarGiTOHscBYXP0LpG6RGCUDjzDCc/5lT+5sZ root@Barbara";
  Rouge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKJXX0hscmQH+yPf8GoBrVLftzw2jaL3fmBQsrDva9AJ root@Rouge";
  Gertrude = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIy9n203h4Qwj7qcWXTsMl9cbkc7wBoSA5o5u9l9gqwk root@Gertrude";
  Waltraud = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMn/iw1G7jjjjlYg+Ac051HNI/t1HMjzdn761bk8slsI root@Waltraud";
  systems = [
    Barbara
    Gertrude
    Waltraud
    Rouge
  ];
in
{
  "secrets/common/aki-password.age".publicKeys = [ aki ] ++ systems;

  "secrets/common/aki-id_ed25519.age".publicKeys = [ aki ] ++ systems;
  "secrets/common/aki-id_ed25519.pub.age".publicKeys = [ aki ] ++ systems;

  "secrets/common/aki-.wakatime.cfg.age".publicKeys = [ aki ] ++ systems;

  "secrets/common/aki-nixpkgs-review-github-token.age".publicKeys = [ aki ] ++ systems;
  "secrets/common/aki-nixpkgs-update-github-token.age".publicKeys = [ aki ] ++ systems;

  "secrets/common/tdarr-apiKey.age".publicKeys = [ aki ] ++ systems;

  "secrets/common/noctalia-github-feed-settings.json.age".publicKeys = [ aki ] ++ systems;
  "secrets/common/noctalia-hassio-settings.json.age".publicKeys = [ aki ] ++ systems;
}
