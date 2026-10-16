set positional-arguments

default:
    echo "Hi"

transpile-to-c source="src/main.ks" output="target/compiled/main.c":
    mkdir -p $(dirname {{output}})
    echo "#define SDL_MAIN_HANDLED 1" > {{output}}
    ${KAST_BIN:-kast} compile \
        --target c \
        {{source}} \
        >> {{output}}
    # --c-debug true \

[arg("sanitize", long, value="true")]
[arg("opt_level", short="O")]
compile-exe source="target/compiled/main.c" opt_level="1" sanitize="":
    #!/usr/bin/env bash
    if [ -z "$KAST_PATH" ]; then
        KAST_ARGS="-lkast"
    else
        KAST_ARGS="-I${KAST_PATH}/c-runtime/include"
        KAST_ARGS="$KAST_ARGS ${KAST_PATH}/c-runtime/src/*.c"
    fi
    ${CC:-gcc} \
        {{source}} \
        -o target/compiled/main.exe \
        $KAST_ARGS \
        -I. \
        -pthread \
        -lm -lSDL3 -lSDL3_image -lSDL3_mixer -lGL -lGLEW -lbacktrace \
        {{ if sanitize == "true" { "-fsanitize=address,leak,undefined" } else { "" } }} \
        -Wfatal-errors \
        -g -O{{opt_level}}
    # -fsanitize=memory \
    # -fno-omit-frame-pointer \

build-emscripten source="target/compiled/main.c":
    rm -rf target/web
    mkdir -p target/web
    emcc {{source}} \
        -I${KAST_PATH}/c-runtime/include \
        ${KAST_PATH}/c-runtime/src/*.c \
        -I. \
        --shell-file shell.html \
        -o target/web/index.html \
        -I ${SDL3_WEB}/include \
        -L ${SDL3_WEB}/lib \
        -l SDL3 \
        -I ${SDL3_IMAGE_WEB}/include \
        -L ${SDL3_IMAGE_WEB}/lib \
        -l SDL3_image \
        -I ${SDL3_MIXER_WEB}/include \
        -L ${SDL3_MIXER_WEB}/lib \
        -l SDL3_mixer \
        -O3 \
        --use-preload-plugins \
        --preload-file assets \
        -s TOTAL_STACK=64MB \
        -s INITIAL_MEMORY=512MB \
        -s ALLOW_MEMORY_GROWTH \
        -s WEBSOCKET_URL="wss://d2jam4.badcop.games" \
        -sMAX_WEBGL_VERSION=2 \
        -s BINARYEN_EXTRA_PASSES='--spill-pointers' \
        -w
    # -s ASSERTIONS \
    # -s ASYNCIFY \
    # -s ASYNCIFY_STACK_SIZE=64MB \

build src="src/main.ks":
    geng transpile-to-c {{src}}
    geng compile-exe

dist:
    rm -rf target/dist
    mkdir -p target/dist
    cp target/compiled/main.exe target/dist/main.exe
    cp -r assets target/dist/assets
    cp -r $GENG_PATH/assets target/dist/assets/geng

run *args:
    ./target/compiled/main.exe {{args}}

serve:
    geng build-c
    geng build-emscripten
    caddy run

exec program *args:
    echo $GENG_PATH
    exec "$@"
