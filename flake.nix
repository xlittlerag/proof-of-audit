{
  description = "A devshell for the Clarinet CLI tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Defines the package itself, which can be built with `nix build .#clarinet`
      packages.clarinet = pkgs.stdenv.mkDerivation rec {
        pname = "clarinet";
        version = "3.6.1";

        # Fetch the pre-compiled binary from the official GitHub release
        src = pkgs.fetchurl {
          url = "https://github.com/hirosystems/clarinet/releases/download/v${version}/clarinet-linux-x64-glibc.tar.gz";
          sha256 = "TDQuRVOadMmCUmjvLiZnypHb3I//6fCLccObZmV7y7M=";
        };

        # autoPatchelfHook automatically patches the binary to use libraries from the Nix store.
        nativeBuildInputs = [pkgs.autoPatchelfHook];

        # These are the runtime dependencies required by the clarinet binary.
        buildInputs = [
          pkgs.libgcc
          pkgs.openssl
        ];

        # The tarball extracts its contents directly to the root, so we set the source root to '.'
        sourceRoot = ".";

        installPhase = ''
          # Ensures destination directory exists and makes the binary executable
          install -D -m755 clarinet $out/bin/clarinet
        '';

        meta = with pkgs.lib; {
          description = "A command line tool for interacting with the Stacks blockchain, designed for developers";
          homepage = "https://github.com/hirosystems/clarinet";
          license = licenses.gpl3Only;
          platforms = ["x86_64-linux"]; # This binary is specific to this platform
          maintainers = []; # You can add your GitHub handle here
        };
      };

      # This defines the default devShell, accessible via `nix develop`
      devShells.default = pkgs.mkShell {
        name = "clarinet-dev-shell";
        # The packages to make available in the shell environment.
        packages = [
          self.packages.${system}.clarinet
          pkgs.nodejs
        ];
        shellHook = ''
          zsh
        '';
      };
    });
}
