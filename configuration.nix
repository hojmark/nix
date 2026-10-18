{ hostname, lib, pkgs, ... }:

let
  hardwareConfiguration = builtins.toPath
    "${toString ./.}/hosts/${hostname}/hardware-configuration.nix";
  bootloaderConfiguration = builtins.toPath
    "${toString ./.}/hosts/${hostname}/bootloader.nix";
in
{
  system.stateVersion = "26.05";

  imports = lib.optionals (builtins.pathExists hardwareConfiguration) [
    hardwareConfiguration
  ] ++ lib.optional (builtins.pathExists bootloaderConfiguration)
    bootloaderConfiguration;

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  
  # Keyboard layout
  services.xserver = {
    enable = true;
    xkb.layout = "dk";
    xkb.variant = "nodeadkeys";
    excludePackages = [ pkgs.xterm ];
  };
  console.keyMap = "dk";

  # GNOME
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    lockAll = true;
    settings = {
      "org/gnome/desktop/input-sources" = {
        sources = [ (lib.gvariant.mkTuple [ "xkb" "dk+nodeadkeys" ]) ];
        current = lib.gvariant.mkUint32 0;
      };
      "org/gnome/shell" = {
        enabled-extensions = [
          "caffeine@patapon.info"
          "display-brightness-ddcutil@themightydeity.github.com"
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
        ];
      };
      "org/gnome/shell/extensions/display-brightness-ddcutil" = {
        button-location = lib.gvariant.mkInt32 1;
        ddcutil-binary-path = "${pkgs.ddcutil}/bin/ddcutil";
        show-display-name = true;
        show-value-label = true;
      };
      "org/gnome/shell/extensions/system-monitor" = {
        show-cpu = true;
        show-memory = true;
        show-swap = false;
        show-upload = false;
        show-download = true;
      };
    };
  }];

  # Programs
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "vscode" ];
  # TODO
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
  services.gnome.core-apps.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];
  programs.gnome-terminal = {
    enable = true;
  };
  programs.git.enable = true;
  programs.firefox.enable = true;
  programs.thunderbird.enable = true;
  programs.vscode.enable = true;
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    dotnet-sdk_10
    dive
    ddcutil
    git-lfs
    podman-compose
    vlc
    logseq
    bitwarden-desktop
    dconf-editor
    resources
    eog
    gradia
    gnomeExtensions.caffeine
    gnomeExtensions.brightness-control-using-ddcutil
    gnomeExtensions.system-monitor
  ];

  # Services
  services.syncthing = {
    enable = true;
    user = "hojmark";
    group = "users";
    dataDir = "/home/hojmark";
    openDefaultPorts = true;
  };
  hardware.i2c.enable = true;

  # Containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Users
  users.users.hojmark = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "i2c" ];
    shell = pkgs.zsh;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # File systems
  # Keep these mounts aligned with disko.nix
  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/NIXOS-ROOT";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/NIXOS-ESP";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
}
