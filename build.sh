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

    if ! git -C "$dir" -c advice.detachedHead=false checkout -f "$revision"; then
        git -C "$dir" fetch origin "$revision"
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

        echo "Submodule pinned revision fetch failed in $dir; retrying from remote heads"
        git -C "$dir" submodule deinit -f --all || true
        rm -rf "$dir/.git/modules"
        git -C "$dir" submodule sync --recursive
        if git -C "$dir" submodule update "${submodule_args[@]}" --remote --depth 1; then
            return
        fi
        git -C "$dir" submodule update "${submodule_args[@]}" --remote
    fi
}

clone_at_revision SDL release-3.4.2 https://github.com/libsdl-org/SDL --depth=1 --recurse-submodules -j 4 --shallow-submodules
clone_at_revision SDL_image release-3.4.0 https://github.com/libsdl-org/SDL_image --depth=1 --recurse-submodules -j 10 --shallow-submodules
clone_at_revision SDL_ttf 053bbc89517471427748a082583c9eada55c07b5 https://github.com/libsdl-org/SDL_ttf --depth=1 --recurse-submodules -j 10 --shallow-submodules
clone_at_revision SDL_mixer release-3.2.0 https://github.com/libsdl-org/SDL_mixer --depth=1 --recurse-submodules -j 4 --shallow-submodules

linux_arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "linux_x64" ;;
        aarch64 | arm64) echo "linux_arm64" ;;
        *) echo "linux_$(uname -m)" ;;
    esac
}

copy_shared_family() {
    local src_dir="$1"
    local lib_base="$2"
    local dst_dir="$3"
    local src
    local copied=0
    for src in "$src_dir"/"$lib_base".so*; do
        [ -e "$src" ] || continue
        cp -a "$src" "$dst_dir"/
        copied=1
    done
    if [ "$copied" -eq 0 ]; then
        echo "WARN: no files matched $src_dir/$lib_base.so*"
    fi
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
    ARCH_DIR=$(linux_arch_dir)
    mkdir -p "$ARCH_DIR" "image/$ARCH_DIR" "ttf/$ARCH_DIR" "mixer/$ARCH_DIR"
    copy_shared_family libs/SDL libSDL3 "$ARCH_DIR"
    copy_shared_family libs/SDL_image libSDL3_image "image/$ARCH_DIR"
    copy_shared_family libs/SDL_ttf libSDL3_ttf "ttf/$ARCH_DIR"
    copy_shared_family libs/SDL_mixer libSDL3_mixer "mixer/$ARCH_DIR"
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
        libwebpdemux.2.dylib; do
        src="$(find libs/SDL_image/external -type f -name "$dylib" -print -quit)"
        if [ -n "$src" ]; then
            cp "$src" image/
        fi
    done
else
    # NOTE: do we actually need aom?
    find libs/SDL_image/external \
        \( -type f -o -type l \) \
        -name "*.so*" \
        -exec cp -a {} "image/$ARCH_DIR"/ \;
fi

cp -r SDL/include/SDL3/* include
cp -r SDL_image/include/SDL3_image/* image/include
cp -r SDL_ttf/include/SDL3_ttf/* ttf/include
cp -r SDL_mixer/include/SDL3_mixer/* mixer/include
