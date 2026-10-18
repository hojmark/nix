{
  description = "Minimal GNOME workstation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit hostname; };
        modules = [ ./configuration.nix ];
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
