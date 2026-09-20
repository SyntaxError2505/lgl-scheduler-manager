{
  description = "LGL SCX Scheduler Manager — Qt6 GUI for managing sched-ext BPF schedulers via scxctl";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    # sched-ext (scx-loader, scx schedulers) is Linux-only
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;
      in
      {
        packages = rec {
          lgl-scxctl-manager = pkgs.stdenv.mkDerivation {
            pname = "lgl-scxctl-manager";
            version = "1.0.1";

            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.gitTracked ./.;
            };

            nativeBuildInputs = with pkgs; [
              cmake
              qt6.wrapQtAppsHook
            ];

            buildInputs = with pkgs; [
              qt6.qtbase
            ];

            # The app shells out to scxctl (directly, and via pkexec) and uses
            # pkexec for privilege elevation. Put both on PATH inside the
            # wrapper; sched-ext schedulers come from pkgs.scx.full.
            qtWrapperArgs = [
              "--prefix PATH : ${
                lib.makeBinPath [
                  pkgs.scx-loader
                  pkgs.polkit
                  pkgs.scx.full
                ]
              }"
            ];

            meta = {
              description = "Qt6 GUI for managing sched-ext BPF schedulers via scxctl";
              homepage = "https://github.com/linuxgamerlife/lgl-scxctl-manager";
              license = lib.licenses.mit;
              mainProgram = "lgl-scxctl-manager";
              platforms = lib.platforms.linux;
            };
          };

          default = lgl-scxctl-manager;
        };

        apps.default = {
          type = "app";
          program = "${lib.getExe self.packages.${system}.default}";
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            qt6.qtbase
            scx-loader
            polkit
            scx.full
          ];
          # Point CMake at the store's Qt6 (plain mkShell doesn't do this
          # automatically); scxctl/pkexec/schedulers land on PATH via packages.
          shellHook = ''
            export CMAKE_PREFIX_PATH="${pkgs.qt6.qtbase}$([ -n "''${CMAKE_PREFIX_PATH:-}" ] && echo ":$CMAKE_PREFIX_PATH")"
          '';
        };
      }
    );
}
