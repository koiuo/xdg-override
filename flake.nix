{
  description = "xdg-override";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" ];
    perSystem = { config, self', inputs', pkgs, system, ... }: {
      devShells.default = pkgs.mkShell {
      };
      packages = rec {
        xdg-override = let
          text = builtins.readFile ./xdg-override;
        in pkgs.writeShellApplication {
          name = "xdg-override";
          text = text;
        };
        default = xdg-override;
      };
    };
  };
}
