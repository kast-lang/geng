{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
    kast.url = "github:kast-lang/kast/bootstrap-ocaml";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
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
      in
      {
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
                just
                caddy
                clang
                tinycc
                emscripten
              ] ++ c_libs;
              SDL3_WEB = "${sdl3-web}";
              SDL3_IMAGE_WEB = "${sdl3-image-web}";
              SDL3_MIXER_WEB = "${sdl3-mixer-web}";
              # LSAN_OPTIONS = "suppresions=suppr.txt";
            };
      });
}

