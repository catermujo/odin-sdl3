@echo off

setlocal EnableDelayedExpansion

if not exist SDL (
   git clone https://github.com/libsdl-org/SDL --revision release-3.4.2 --depth=1 --recurse-submodules -j 4
)
if not exist SDL_image (
   git clone https://github.com/libsdl-org/SDL_image --revision release-3.4.0 --depth=1 --recurse-submodules -j 10
)
if not exist SDL_mixer (
   git clone https://github.com/libsdl-org/SDL_mixer --revision 37b2f3325a0fb1e98ba265aa38826aa9e16624fb --depth=1 --recurse-submodules -j 4
)
if not exist SDL_ttf (
   git clone https://github.com/libsdl-org/SDL_ttf --revision 053bbc89517471427748a082583c9eada55c07b5 --depth=1 --recurse-submodules -j 10
)

rem Apply patches
for %%p in (patches\*.patch) do (
   git -C SDL am --3way "%%p" 2>nul || echo Patch %%p skipped
)

cmake -S . -B build -DSDL_STATIC=ON -DSDL_SHARED=OFF -DBUILD_SHARED_LIBS=OFF -DSDLIMAGE_AVIF=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build -j%NUMBER_OF_PROCESSORS% --config Release

copy /y build\SDL\Release\SDL3-static.lib             SDL3_static.lib
copy /y build\SDL_image\Release\SDL3_image-static.lib image\SDL3_image_static.lib
copy /y build\SDL_mixer\Release\SDL3_mixer-static.lib mixer\SDL3_mixer_static.lib
copy /y build\SDL_ttf\Release\SDL3_ttf-static.lib     ttf\SDL3_ttf_static.lib
