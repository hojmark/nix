{
  description = "Minimal GNOME workstation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.8.0";

  outputs = { self, nixpkgs, nix-flatpak, ... }:
    let
      system = "x86_64-linux";
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit hostname; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./configuration.nix
        ];
      };
      mkDisko = args: import ./disko.nix args;
    in
    {
      # Disko receives diskDevice from its --argstr command-line parameter.
      diskoConfigurations = {
        abc = mkDisko;
        t14 = mkDisko;
      };

      nixosConfigurations = {
        abc = mkHost "abc";
        t14 = mkHost "t14";
      };
    };
}
