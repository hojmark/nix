#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/hojmark/nix.git"
repo_dir="$HOME/git/nix"
system_configuration=/etc/nixos/configuration.nix
backup_configuration=/etc/nixos/configuration.nix.pre-repo-link-bak

mkdir -p "$HOME/git"
if [[ ! -d $repo_dir ]]; then
  git clone "$repo_url" "$repo_dir"
fi

sudo mv "$system_configuration" "$backup_configuration"
sudo ln -s "$repo_dir/configuration.nix" "$system_configuration"
