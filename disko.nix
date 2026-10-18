{ diskDevice, bios ? false, lib, ... }:

{
  disko.devices.disk.main = {
    device = diskDevice;
    type = "disk";
    content = {
      type = "gpt";
      partitions = (lib.optionalAttrs bios {
        # BIOS boot partition for GRUB on GPT; not formatted or mounted.
        BIOS = {
          priority = 0;
          size = "1M";
          type = "EF02";
        };
      }) // {
        # UEFI EFI System Partition; the EF02 BIOS partition is optional via `bios = true`.
        ESP = {
          priority = 1;
          name = "NIXOS-ESP";
          label = "NIXOS-ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          priority = 2;
          name = "NIXOS-ROOT";
          label = "NIXOS-ROOT";
          size = "100%";
          content = {
            type = "filesystem";
            format = "btrfs";
            mountpoint = "/";
            mountOptions = [ "compress=zstd" "noatime" ];
          };
        };
      };
    };
  };
}
