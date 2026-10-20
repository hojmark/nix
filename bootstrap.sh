#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: sudo %s <abc|t14> <disk-device> [--bios]\n' "$0" >&2
  printf 'Example: sudo %s abc /dev/disk/by-id/your-disk-id\n' "$0" >&2
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 2
fi

host=$1
disk=$2
bios=false
if [[ ${3:-} == --bios ]]; then
  bios=true
elif [[ $# -eq 3 ]]; then
  usage
  exit 2
fi

case "$host" in
  abc|t14) ;;
  *) printf 'Unknown host: %s (expected abc or t14)\n' "$host" >&2; exit 2 ;;
esac

if [[ $EUID -ne 0 ]]; then
  printf 'Run this script as root (sudo %s %s %s).\n' "$0" "$host" "$disk" >&2
  exit 1
fi

if [[ ! -b $disk ]]; then
  printf 'Disk path is not a block device: %s\n' "$disk" >&2
  exit 1
fi

command -v nix >/dev/null || { printf 'Nix is required. Boot the NixOS installer first.\n' >&2; exit 1; }
command -v curl >/dev/null || { printf 'curl is required to fetch Disko.\n' >&2; exit 1; }
command -v tar >/dev/null || { printf 'tar is required to unpack Disko.\n' >&2; exit 1; }
export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG$'\n'}experimental-features = nix-command flakes"

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
target_root=/mnt
config_dir="$target_root/etc/nixos"

printf 'Host: %s\nDisk: %s -> %s\n' "$host" "$disk" "$(readlink -f -- "$disk")"
if [[ $bios == true ]]; then
  printf 'Adding a GPT BIOS boot partition (EF02).\n'
fi
printf 'This will ERASE the selected disk and install NixOS. Type the host name (%s) to continue: ' "$host"
read -r confirmation
[[ $confirmation == "$host" ]] || { printf 'Cancelled.\n'; exit 1; }

disko_src=$(mktemp -d)
trap 'rm -rf "$disko_src"' EXIT
DISKO_VERSION=v1.13.0
curl --fail --location --silent --show-error \
  "https://github.com/nix-community/disko/archive/refs/tags/$DISKO_VERSION.tar.gz" \
  | tar -xz --strip-components=1 -C "$disko_src"

disk_args=(
  --no-deps
  --flake "path:$repo_dir#$host"
  --argstr diskDevice "$disk"
  --mode destroy,format,mount
)
if [[ $bios == true ]]; then
  disk_args+=(--arg bios true)
fi

DISKO_VERSION="$DISKO_VERSION" bash "$disko_src/disko" \
  "${disk_args[@]}"

read -rp 'Press enter to continue...'

nixos-generate-config --no-filesystems --root "$target_root"

read -rp 'Press enter to continue...'

mkdir -p "$config_dir/hosts/$host"
cp -a "$repo_dir/"*.nix "$config_dir/"
install -m 0755 "$repo_dir/post-install.sh" "$config_dir/post-install.sh"
cp "$config_dir/hardware-configuration.nix" "$config_dir/hosts/$host/"
if [[ $bios == true ]]; then
  printf '{ lib, ... }: {\n  boot.loader.systemd-boot.enable = lib.mkForce false;\n  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;\n  boot.loader.grub = {\n    enable = true;\n    device = "%s";\n  };\n}\n' "$(readlink -f -- "$disk")" \
    > "$config_dir/hosts/$host/bootloader.nix"
else
  rm -f "$config_dir/hosts/$host/bootloader.nix"
fi

read -rp 'Press enter to continue...'

# Create the lock before nixos-install evaluates the local flake. Letting
# nixos-install create it during evaluation can change the path hash midway.
nix flake lock "path:$config_dir"

read -rp 'Press enter to continue...'

nixos-install --root "$target_root" --flake "path:$config_dir#$host"

read -rp 'Press enter to continue...'

printf '\nSet the user password before rebooting:\n'
nixos-enter --root "$target_root" -c 'passwd hojmark'
printf 'Installation complete. Reboot when ready.\n'
