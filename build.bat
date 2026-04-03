@echo off

setlocal EnableDelayedExpansion

if not exist SDL (
   git clone https://github.com/libsdl-org/SDL --revision release-3.4.2 --depth=1 --recurse-submodules -j 4
)
if not exist SDL_image (
   git clone https://github.com/libsdl-org/SDL_image --revision release-3.4.0 --depth=1 --recurse-submodules -j 10
)
if not exist SDL_mixer (
   rem SDL_mixer now publishes a release tag for this snapshot, so pin the build to the named 3.2.0 release instead of a floating commit hash.
   git clone https://github.com/libsdl-org/SDL_mixer --revision release-3.2.0 --depth=1 --recurse-submodules -j 4
)
if not exist SDL_ttf (
   git clone https://github.com/libsdl-org/SDL_ttf --revision 053bbc89517471427748a082583c9eada55c07b5 --depth=1 --recurse-submodules -j 10
)

rem Apply patches
for %%p in (patches\*.patch) do (
   git -C SDL am --3way "%%p" 2>nul || echo Patch %%p skipped
)

cmake -S . -B build -DSDL_STATIC=OFF -DSDL_SHARED=ON -DBUILD_SHARED_LIBS=ON -DSDLIMAGE_AVIF=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build -j%NUMBER_OF_PROCESSORS% --config Release

copy /y build\SDL\Release\SDL3.lib             SDL3.lib
copy /y build\SDL_image\Release\SDL3_image.lib image\SDL3_image.lib
copy /y build\SDL_mixer\Release\SDL3_mixer.lib mixer\SDL3_mixer.lib
copy /y build\SDL_ttf\Release\SDL3_ttf.lib     ttf\SDL3_ttf.lib

copy /y build\SDL\Release\SDL3.dll             SDL3.dll
copy /y build\SDL_image\Release\SDL3_image.dll image\SDL3_image.dll
copy /y build\SDL_mixer\Release\SDL3_mixer.dll mixer\SDL3_mixer.dll
copy /y build\SDL_ttf\Release\SDL3_ttf.dll     ttf\SDL3_ttf.dll
