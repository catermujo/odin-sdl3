#!/usr/bin/env bash

set -e

clone_at_revision() {
    local dir="$1"
    local revision="$2"
    local remote="$3"
    shift 3
    [ -d "$dir" ] && return
    git clone "$@" "$remote" "$dir"
    if ! git -C "$dir" checkout --detach "$revision"; then
        git -C "$dir" fetch origin "$revision"
        git -C "$dir" checkout --detach FETCH_HEAD
    fi
    if [ -f "$dir/.gitmodules" ]; then
        git -C "$dir" submodule update --init --recursive
    fi
}

clone_at_revision SDL release-3.4.2 https://github.com/libsdl-org/SDL --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_image release-3.4.0 https://github.com/libsdl-org/SDL_image --depth=1 --recurse-submodules -j 10 --shallow-submodules
clone_at_revision SDL_mixer release-3.2.0 https://github.com/libsdl-org/SDL_mixer --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_ttf 053bbc89517471427748a082583c9eada55c07b5 https://github.com/libsdl-org/SDL_ttf --depth=1 --recurse-submodules -j 10 --shallow-submodules

# Apply patches
for patch in patches/*.patch; do
    [ -f "$patch" ] && git -C SDL am --3way "$PWD/$patch" 2>/dev/null || true
done

emcmake cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DDAV1D_ASM=OFF -DEMSCRIPTEN=ON -DSDLIMAGE_AVIF=OFF
if [ $(uname -s) = 'Darwin' ]; then
    emmake make -C build -j$(sysctl -n hw.ncpu)
else
    emmake make -C build -j$(nproc)
fi

cp build/SDL/libSDL3.a SDL3.wasm.a
cp build/SDL_image/libSDL3_image.a image/SDL3_image.wasm.a
cp build/SDL_ttf/libSDL3_ttf.a ttf/SDL3_ttf.wasm.a
cp build/SDL_mixer/libSDL3_mixer.a mixer/SDL3_mixer.wasm.a
