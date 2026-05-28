#!/usr/bin/env bash

set -e

clone_at_revision() {
    local dir="$1"
    local revision="$2"
    local remote="$3"
    shift 3
    [ -d "$dir" ] && return
    local clone_args=("$@")
    if ! git clone "${clone_args[@]}" "$remote" "$dir"; then
        local has_shallow_submodules=0
        local fallback_args=()
        local arg
        for arg in "${clone_args[@]}"; do
            if [ "$arg" = "--shallow-submodules" ]; then
                has_shallow_submodules=1
                continue
            fi
            fallback_args+=("$arg")
        done
        if [ "$has_shallow_submodules" -eq 0 ]; then
            return 1
        fi
        rm -rf "$dir"
        git clone "${fallback_args[@]}" "$remote" "$dir"
    fi
    if ! git -C "$dir" checkout --detach "$revision"; then
        git -C "$dir" fetch origin "$revision"
        git -C "$dir" checkout --detach FETCH_HEAD
    fi
    if [ -f "$dir/.gitmodules" ]; then
        if ! git -C "$dir" submodule update --init --recursive; then
            git -C "$dir" submodule sync --recursive
            git -C "$dir" submodule update --init --recursive
        fi
    fi
}

clone_at_revision SDL release-3.4.2 https://github.com/libsdl-org/SDL --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_image release-3.4.0 https://github.com/libsdl-org/SDL_image --depth=1 --recurse-submodules -j 10 --shallow-submodules
clone_at_revision SDL_mixer release-3.2.0 https://github.com/libsdl-org/SDL_mixer --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_ttf 053bbc89517471427748a082583c9eada55c07b5 https://github.com/libsdl-org/SDL_ttf --depth=1 --recurse-submodules -j 10 --shallow-submodules

linux_arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "linux_x64" ;;
        aarch64 | arm64) echo "linux_arm64" ;;
        *) echo "linux_$(uname -m)" ;;
    esac
}

# Apply patches
for patch in patches/*.patch; do
    [ -f "$patch" ] && git -C SDL am --3way "$PWD/$patch" 2>/dev/null || true
done

EXTRA_CMAKE_FLAGS=()
if [ "$(uname -s)" = 'Linux' ]; then
    # DUMBAI: Vendored Vorbis in SDL_mixer expects HAVE_ALLOCA_H from autotools; define it explicitly in our CMake flow.
    EXTRA_CMAKE_FLAGS+=(-DCMAKE_C_FLAGS=-DHAVE_ALLOCA_H=1)
fi

cmake -S . -B libs -DSDL_SHARED=OFF -DSDL_STATIC=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DSDLIMAGE_AVIF=OFF "${EXTRA_CMAKE_FLAGS[@]}"
if [ "$(uname -s)" = 'Darwin' ]; then
    cmake --build libs -j$(sysctl -n hw.ncpu) --config Release
    LIB_EXT=darwin
else
    cmake --build libs -j$(nproc) --config Release
    ARCH_DIR=$(linux_arch_dir)
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    cp libs/SDL/libSDL3.a SDL3.$LIB_EXT.a
    cp libs/SDL_image/libSDL3_image.a image/SDL3_image.$LIB_EXT.a
    cp libs/SDL_ttf/libSDL3_ttf.a ttf/SDL3_ttf.$LIB_EXT.a
    cp libs/SDL_mixer/libSDL3_mixer.a mixer/SDL3_mixer.$LIB_EXT.a
else
    mkdir -p "$ARCH_DIR" "image/$ARCH_DIR" "ttf/$ARCH_DIR" "mixer/$ARCH_DIR"
    cp libs/SDL/libSDL3.a "$ARCH_DIR/SDL3.linux.a"
    cp libs/SDL_image/libSDL3_image.a "image/$ARCH_DIR/SDL3_image.linux.a"
    cp libs/SDL_ttf/libSDL3_ttf.a "ttf/$ARCH_DIR/SDL3_ttf.linux.a"
    cp libs/SDL_mixer/libSDL3_mixer.a "mixer/$ARCH_DIR/SDL3_mixer.linux.a"
fi
