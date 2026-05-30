#!/usr/bin/env bash

set -e

clone_at_revision() {
    local dir="$1"
    local revision="$2"
    local remote="$3"
    shift 3
    local clone_args=("$@")
    local filtered_clone_args=()
    local has_recurse_submodules=0
    local has_shallow_submodules=0
    local arg
    for arg in "${clone_args[@]}"; do
        case "$arg" in
            --recurse-submodules)
                has_recurse_submodules=1
                ;;
            --shallow-submodules)
                has_shallow_submodules=1
                ;;
            *)
                filtered_clone_args+=("$arg")
                ;;
        esac
    done

    if [ -d "$dir" ] && [ ! -d "$dir/.git" ]; then
        rm -rf "$dir"
    fi

    if [ ! -d "$dir/.git" ]; then
        if ! git clone "${filtered_clone_args[@]}" "$remote" "$dir"; then
            if [ "$has_shallow_submodules" -eq 0 ]; then
                return 1
            fi
            local fallback_args=()
            for arg in "${filtered_clone_args[@]}"; do
                if [ "$arg" = "--depth=1" ] || [ "$arg" = "--depth" ]; then
                    continue
                fi
                fallback_args+=("$arg")
            done
            rm -rf "$dir"
            git clone "${fallback_args[@]}" "$remote" "$dir"
        fi
    fi

    local fetch_ref="$revision"
    if [ "${revision#refs/}" != "$revision" ]; then
        fetch_ref="$revision:$revision"
    fi

    if ! git -C "$dir" rev-parse -q --verify "$revision^{commit}" >/dev/null; then
        git -C "$dir" fetch origin "$fetch_ref"
    fi

    if ! git -C "$dir" -c advice.detachedHead=false checkout -f "$revision"; then
        git -C "$dir" -c advice.detachedHead=false checkout -f FETCH_HEAD
    fi

    if [ "$has_recurse_submodules" -eq 1 ] && [ -f "$dir/.gitmodules" ]; then
        local submodule_args=(--init --recursive)
        if [ "$dir" = "SDL_mixer" ]; then
            submodule_args+=(
                external/flac
                external/ogg
                external/opus
                external/opusfile
                external/tremor
                external/vorbis
            )
        fi

        if git -C "$dir" submodule update "${submodule_args[@]}" --depth 1; then
            return
        fi
        git -C "$dir" submodule sync --recursive
        if git -C "$dir" submodule update "${submodule_args[@]}"; then
            return
        fi

        echo "Submodule pinned revision fetch failed in $dir; retrying pinned refs without shallow mode"
        git -C "$dir" submodule deinit -f --all || true
        rm -rf "$dir/.git/modules"
        git -C "$dir" submodule sync --recursive
        git -C "$dir" submodule update "${submodule_args[@]}"
    fi
}

clone_at_revision SDL refs/tags/release-3.4.2 https://github.com/libsdl-org/SDL --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_image refs/tags/release-3.4.0 https://github.com/libsdl-org/SDL_image --depth=1 --recurse-submodules -j 10 --shallow-submodules
clone_at_revision SDL_mixer refs/tags/release-3.2.0 https://github.com/libsdl-org/SDL_mixer --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_ttf 053bbc89517471427748a082583c9eada55c07b5 https://github.com/libsdl-org/SDL_ttf --depth=1 --recurse-submodules -j 10 --shallow-submodules

linux_arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "linux_x64" ;;
        aarch64 | arm64) echo "linux_arm64" ;;
        *) echo "linux_$(uname -m)" ;;
    esac
}

darwin_arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "darwin_x64" ;;
        aarch64 | arm64) echo "darwin_arm64" ;;
        *) echo "darwin_$(uname -m)" ;;
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
    ARCH_DIR=$(darwin_arch_dir)
    mkdir -p "$ARCH_DIR" "image/$ARCH_DIR" "ttf/$ARCH_DIR" "mixer/$ARCH_DIR"
    cmake --build libs -j$(sysctl -n hw.ncpu) --config Release
    LIB_EXT=darwin
else
    cmake --build libs -j$(nproc) --config Release
    ARCH_DIR=$(linux_arch_dir)
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    cp libs/SDL/libSDL3.a "$ARCH_DIR/SDL3.$LIB_EXT.a"
    cp libs/SDL_image/libSDL3_image.a "image/$ARCH_DIR/SDL3_image.$LIB_EXT.a"
    cp libs/SDL_ttf/libSDL3_ttf.a "ttf/$ARCH_DIR/SDL3_ttf.$LIB_EXT.a"
    cp libs/SDL_mixer/libSDL3_mixer.a "mixer/$ARCH_DIR/SDL3_mixer.$LIB_EXT.a"
else
    mkdir -p "$ARCH_DIR" "image/$ARCH_DIR" "ttf/$ARCH_DIR" "mixer/$ARCH_DIR"
    cp libs/SDL/libSDL3.a "$ARCH_DIR/SDL3.linux.a"
    cp libs/SDL_image/libSDL3_image.a "image/$ARCH_DIR/SDL3_image.linux.a"
    cp libs/SDL_ttf/libSDL3_ttf.a "ttf/$ARCH_DIR/SDL3_ttf.linux.a"
    cp libs/SDL_mixer/libSDL3_mixer.a "mixer/$ARCH_DIR/SDL3_mixer.linux.a"
fi
