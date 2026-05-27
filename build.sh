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

clone_at_revision SDL release-3.4.2 https://github.com/libsdl-org/SDL --depth=1 --recurse-submodules -j 4
clone_at_revision SDL_image release-3.4.0 https://github.com/libsdl-org/SDL_image --depth=1 --recurse-submodules -j 10
clone_at_revision SDL_ttf 053bbc89517471427748a082583c9eada55c07b5 https://github.com/libsdl-org/SDL_ttf --depth=1 --recurse-submodules -j 10
clone_at_revision SDL_mixer release-3.2.0 https://github.com/libsdl-org/SDL_mixer --depth=1 --recurse-submodules -j 4

# Apply patches
for patch in patches/*.patch; do
    [ -f "$patch" ] && git -C SDL am --3way "$PWD/$patch" 2>/dev/null || true
done

EXTRA_CMAKE_FLAGS=()
if [ "$(uname -s)" = 'Linux' ]; then
    # DUMBAI: Vendored Vorbis in SDL_mixer expects HAVE_ALLOCA_H from autotools; define it explicitly in our CMake flow.
    EXTRA_CMAKE_FLAGS+=(-DCMAKE_C_FLAGS=-DHAVE_ALLOCA_H=1)
fi

cmake -S . -B libs -DSDL_SHARED=ON -DSDL_STATIC=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DSDLIMAGE_AVIF=ON "${EXTRA_CMAKE_FLAGS[@]}"
if [ "$(uname -s)" = 'Darwin' ]; then
    cmake --build libs -j$(sysctl -n hw.ncpu) --config Release
    LIB_EXT=dylib
else
    cmake --build libs -j$(nproc) --config Release
    LIB_EXT=so
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    # DUMBAI: Keep only ABI-major SDL dylib names in vendor output; Odin bindings import these directly to avoid duplicate unversioned aliases.
    cp libs/SDL/libSDL3.0.dylib .
    cp libs/SDL_image/libSDL3_image.0.dylib image/
    cp libs/SDL_ttf/libSDL3_ttf.0.dylib ttf/
    cp libs/SDL_mixer/libSDL3_mixer.0.dylib mixer/
else
    cp libs/SDL/*.$LIB_EXT .
    cp libs/SDL_image/*.$LIB_EXT image/
    cp libs/SDL_ttf/*.$LIB_EXT ttf/
    cp libs/SDL_mixer/*.$LIB_EXT mixer/
fi
if [ "$(uname -s)" = 'Darwin' ]; then
    # DUMBAI: Stage only ABI-major external SDL_image dylibs so vendor output does not duplicate unversioned and patch-level aliases.
    for dylib in \
        libaom.3.dylib \
        libaom_version.dylib \
        libavif.16.dylib \
        libdav1d.6.dylib \
        libpng16.16.dylib \
        libwebp.7.dylib \
        libwebpdemux.2.dylib
    do
        src="$(find libs/SDL_image/external -type f -name "$dylib" -print -quit)"
        if [ -n "$src" ]; then
            cp "$src" image/
        fi
    done
else
    # NOTE: do we actually need aom?
    cp libs/SDL_image/external/**/*.$LIB_EXT image/
fi

cp -r SDL/include/SDL3/* include
cp -r SDL_image/include/SDL3_image/* image/include
cp -r SDL_ttf/include/SDL3_ttf/* ttf/include
cp -r SDL_mixer/include/SDL3_mixer/* mixer/include
