#!/usr/bin/env bash

set -e

[ -d SDL ] || git clone https://github.com/libsdl-org/SDL --revision release-3.4.0 --depth=1 --recurse-submodules -j 4 &
[ -d SDL_image ] || git clone https://github.com/libsdl-org/SDL_image --revision release-3.4.0 --depth=1 --recurse-submodules -j 10 &
[ -d SDL_ttf ] || git clone https://github.com/libsdl-org/SDL_ttf --revision 053bbc89517471427748a082583c9eada55c07b5 --depth=1 --recurse-submodules -j 10 &
[ -d SDL_mixer ] || git clone https://github.com/libsdl-org/SDL_mixer --revision 37b2f3325a0fb1e98ba265aa38826aa9e16624fb --depth=1 --recurse-submodules -j 4 &

wait

# Apply patches
for patch in patches/*.patch; do
    [ -f "$patch" ] && git -C SDL am --3way "$PWD/$patch" 2>/dev/null || true
done

cmake -S . -B libs -DSDL_SHARED=ON -DSDL_STATIC=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DSDLIMAGE_AVIF=ON
if [ $(uname -s) = 'Darwin' ]; then
    cmake --build libs -j$(sysctl -n hw.ncpu) --config Release
    LIB_EXT=dylib
else
    cmake --build libs -j$(nproc) --config Release
    LIB_EXT=so
fi

cp libs/SDL/*.$LIB_EXT .
cp libs/SDL_image/*.$LIB_EXT image/
# NOTE: do we actually need aom?
cp libs/SDL_image/external/**/*.$LIB_EXT image/
cp libs/SDL_ttf/*.$LIB_EXT ttf/
cp libs/SDL_mixer/*.$LIB_EXT mixer/

cp -r SDL/include/SDL3/* include
cp -r SDL_image/include/SDL3_image/* image/include
cp -r SDL_ttf/include/SDL3_ttf/* ttf/include
cp -r SDL_mixer/include/SDL3_mixer/* mixer/include
