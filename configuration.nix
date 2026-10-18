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
  };
  console.keyMap = "dk";

  # GNOME
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/input-sources" = {
        sources = [ (lib.gvariant.mkTuple [ "xkb" "dk" ]) ];
        current = lib.gvariant.mkUint32 0;
      };
    };
  }];

  # Programs
  services.gnome.core-apps.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour pkgs.xterm ];
  programs.gnome-terminal = {
    enable = true;
  };
  programs.firefox.enable = true;

  # Users
  users.users.hojmark = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
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
