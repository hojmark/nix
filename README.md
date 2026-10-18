# Minimal NixOS workstation

## Install

1. Boot the [NixOS installer](https://nixos.org/download/).
2. Clone this repo:

   ```sh
   git clone https://github.com/hojmark/nix.git /tmp/nix
   ```

3. Identify the target disk (whole disk, not a partition). `/dev/disk/by-id/...` / `/dev/vda` is all fine:

   ```sh
   lsblk -d -o NAME,MODEL,SIZE,TRAN,SERIAL
   ls -l /dev/disk/by-id/
   ```

4. Run bootstrap with the host (`abc` or `t14`) and disk path. It confirms before erasing the selected disk:

   ```sh
   sudo /tmp/nix/nixos/bootstrap.sh abc /dev/disk/by-id/REPLACE_WITH_TARGET_DISK
   ```

   Optionally, add `--bios`, e.g. `sudo /tmp/nix/nixos/bootstrap.sh abc /dev/vda --boot` for legacy BIOS support.

5. Set the user account password when prompted.
6. Unmount NixOS installer and reboot.