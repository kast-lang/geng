{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
    kast.url = "github:kast-lang/kast/bootstrap-ocaml";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        nix-filter = inputs.nix-filter.lib;
        pkgs-25-11 = import inputs.nixpkgs-25-11 { inherit system; };
        pkgs = import inputs.nixpkgs { inherit system; };
        emscripten = pkgs-25-11.emscripten;
        kast = inputs.kast.packages.${system}.default;
        kast-c-runtime = inputs.kast.packages.${system}.c-runtime;
        sdl3-web = with pkgs-25-11;
          stdenv.mkDerivation {
            name = "sdl3-web";
            src = fetchFromGitHub {
              owner = "libsdl-org";
              repo = "SDL";
              rev = "release-3.4.14";
              hash = "sha256-HzV5Fq+PhJr/dQBCVm2WL1BdaI4GG+W+B0scttjdRuQ=";
            };
            buildInputs = [
              emscripten
              cmake
            ];
            dontUseCmakeConfigure = true;
            buildPhase = ''
              emcmake cmake .
              emmake make
            '';
            installPhase = ''
              cmake --install . --prefix $out
            '';
          };
        sdl3-image-web = with pkgs-25-11;
          stdenv.mkDerivation {
            name = "sdl3-image-web";
            src = fetchFromGitHub {
              owner = "libsdl-org";
              repo = "SDL_image";
              rev = "release-3.4.4";
              hash = "sha256-ttnoe9bTtA8+eUMOs55v58xb+cWpNEiiTDEeX9GBxaw=";
            };
            buildInputs = [
              emscripten
              cmake
            ];
            dontUseCmakeConfigure = true;
            buildPhase = ''
              emcmake cmake . \
                -DSDL3_DIR=${sdl3-web}/lib/cmake/SDL3
              emmake make
            '';
            installPhase = ''
              cmake --install . --prefix $out
            '';
          };
        sdl3-mixer-web = with pkgs-25-11;
          stdenv.mkDerivation {
            name = "sdl3-mixer-web";
            src = fetchFromGitHub {
              owner = "libsdl-org";
              repo = "SDL_mixer";
              rev = "release-3.2.4";
              hash = "sha256-mPk6xU1/GkBtWgF8S9ttha7/PNxcBEiSxpzo6ARLC9I=";
            };
            buildInputs = [
              emscripten
              cmake
            ];
            dontUseCmakeConfigure = true;
            buildPhase = ''
              emcmake cmake . \
                -DSDL3_DIR=${sdl3-web}/lib/cmake/SDL3
              emmake make
            '';
            installPhase = ''
              cmake --install . --prefix $out
            '';
          };
        c_libs = with pkgs; [
          sdl3
          sdl3-image
          sdl3-mixer
          libGL
          glew
          libbacktrace
          libunwind
          kast-c-runtime
        ];
        compilers = with pkgs; [
          just
          caddy
          clang
          tinycc
          emscripten
        ];
      in
      {
        packages = rec {
          default = geng;
          geng = pkgs.stdenv.mkDerivation {
            name = "geng";
            src = nix-filter {
              root = ./.;
              include = [ "assets" "deps" "src" "docker" ".justfile" "Caddyfile" "geng.sh" ];
            };
            buildPhase = ''
              cat >>geng.sh <<"EOF"
              export GENG_PATH=$(realpath $(dirname $0)/..)
              export KAST_PATH=${kast}
              export SDL3_WEB=${sdl3-web}
              export SDL3_IMAGE_WEB=${sdl3-image-web}
              export SDL3_MIXER_WEB=${sdl3-mixer-web}
              export PATH="${pkgs.lib.makeBinPath compilers}:$PATH"
              ${pkgs.just}/bin/just --justfile=${./.justfile} --working-directory=. "$@"
              EOF
            '';
            installPhase = ''
              install -d $out/bin
              install geng.sh $out/bin/geng
              cp -r deps $out/deps
              cp -r src $out/src
              cp -r assets $out/assets
              cp -r docker $out/docker
              cp -r Caddyfile $out/Caddyfile
              cp -r .justfile $out/.justfile
            '';
            propagatedBuildInputs = [
              kast
            ] ++ c_libs;
          };
        };
        devShells.default = with pkgs;
          mkShell
            {
              packages = [
                (pkgs.writeShellScriptBin "kast" ''
                  systemd-run --user --scope -p MemoryMax=10G \
                    rlwrap ${kast}/bin/kast "$@"
                '')
                rlwrap
                nixfmt
              ] ++ compilers ++ c_libs;
              sdl3_web = "${sdl3-web}";
              sdl3_image_web = "${sdl3-image-web}";
              sdl3_mixer_web = "${sdl3-mixer-web}";
              # lsan_options = "suppresions=suppr.txt";
            };
      });
}

