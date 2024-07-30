{
  description = "xdg-override";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }: let
    proxyText = { nameMatch, delegate }: let
      _ = assert (builtins.typeOf nameMatch == "list" && builtins.length nameMatch > 0); null;
      conditions = map ({ case, command }: ''if [[ "$1" =~ ${case} ]]; then ${command} "$1" & exit 0'') nameMatch;
      conditionsStr = builtins.concatStringsSep "\nel" conditions;
    in ''
      ${conditionsStr}
      else ${delegate} "$1"
      fi
    '';
  in flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "aarch64-linux"
      "armv6l-linux"
      "armv7l-linux"
      "i686-linux"
      "riscv64-linux"
      "x86_64-linux"
    ];
    perSystem = { config, self', inputs', pkgs, system, ... }: {
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
    flake.lib = {
      /*
      Generate an overlay with patched xdg-utils package

      DO NOT USE: causes rebuild of entire Nix store
      */
      overlay = { nameMatch } : final : prev : {
        xdg-utils =
          prev.symlinkJoin {
            name = "xdg-utils";
            paths = [ prev.xdg-utils ];
            buildInputs = [ prev.makeWrapper ];
            postBuild = ''
              mv $out/bin/xdg-open $out/bin/.xdg-open
              cat <<EOF > $out/bin/xdg-open
              ${proxyText { inherit nameMatch; delegate = "$out/bin/.xdg-open"; }}
              EOF
              chmod +x $out/bin/xdg-open
            '';
          };
      };
      /*
      Wrap a single package injecting xdg-open proxy into its PATH
      */
      wrapPackage = { pkgs }: { nameMatch }: pkg: let
        proxy = proxyText { inherit nameMatch; delegate = "${pkgs.xdg-utils}/bin/xdg-open"; };
        proxyApp = pkgs.writeShellApplication {
          name = "xdg-open";
          checkPhase = "true";
          text = ''
            ${proxy}
          '';
        };
        pname = pkg.out.pname;
      in pkgs.symlinkJoin {
        name = pkg.name;
        paths = [ pkg ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/${pname}" --prefix PATH : "${proxyApp}/bin"
          for desktopFile in $out/share/applications/*; do
          cp --remove-destination $(readlink -e "$desktopFile") "$desktopFile"
          sed -i -e 's:${pkg}/bin/${pname}:${pname}:' "$desktopFile"
          done
        '';
      };
    };
  };
}
