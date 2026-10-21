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
compile-exe opt_level="1" sanitize="" *sources="target/compiled/main.c":
    #!/usr/bin/env bash
    if [ -z "$KAST_PATH" ]; then
        KAST_ARGS="-lkast"
    else
        KAST_ARGS="-I${KAST_PATH}/c-runtime/include"
        KAST_ARGS="$KAST_ARGS ${KAST_PATH}/c-runtime/src/*.c"
    fi
    set -x
    ${CC:-gcc} \
        {{sources}} \
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
        --preload-file $GENG_PATH/assets@assets/geng \
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

build-tcc:
    CC=tcc geng build-podman

build-podman:
    podman build -t notnix $GENG_PATH/docker
    podman run -it \
        -e CC=$CC \
        -v $KAST_PATH:/kast:ro \
        -e KAST_PATH=/kast \
        -v $GENG_PATH:/geng:ro \
        -e GENG_PATH=/geng \
        -v $(pwd):/src -w /src \
        notnix \
        just --justfile=/geng/.justfile --working-directory=/src compile-exe

run-podman *args:
    xhost +local:users
    podman run -it \
        --env DISPLAY=$DISPLAY \
        -e PULSE_SERVER=unix:/tmp/pulse/native \
        -e PULSE_COOKIE=/tmp/pulse/cookie \
        -v $XDG_RUNTIME_DIR/pulse/native:/tmp/pulse/native:ro \
        -v ~/.config/pulse/cookie:/tmp/pulse/cookie:ro \
        -e XDG_RUNTIME_DIR=/tmp/runtime \
        --volume /tmp/.X11-unix:/tmp/.X11-unix \
        --device /dev/dri \
        --device /dev/kfd \
        --group-add keep-groups \
        -v $XDG_RUNTIME_DIR/pipewire-0:/tmp/runtime/pipewire-0:ro \
        -v $GENG_PATH:/geng:ro \
        -e GENG_PATH=/geng \
        -v $(pwd):/src -w /src \
        notnix \
        ./target/compiled/main.exe {{args}}


serve:
    caddy run --config $GENG_PATH/Caddyfile

exec program *args:
    echo $GENG_PATH
    exec "$@"
