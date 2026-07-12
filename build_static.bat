@echo off

setlocal EnableDelayedExpansion

set "VENDOR_WINDOWS_ARCH=%VSCMD_ARG_TGT_ARCH%"
if not defined VENDOR_WINDOWS_ARCH set "VENDOR_WINDOWS_ARCH=%PROCESSOR_ARCHITECTURE%"
if /I "%VENDOR_WINDOWS_ARCH%"=="AMD64" set "VENDOR_WINDOWS_ARCH=x64"
if /I "%VENDOR_WINDOWS_ARCH%"=="ARM64" set "VENDOR_WINDOWS_ARCH=arm64"
if /I "%VENDOR_WINDOWS_ARCH%"=="X86" set "VENDOR_WINDOWS_ARCH=x64"
set BUILD_DIR=build_static
set output_dir=windows_%VENDOR_WINDOWS_ARCH%

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

cmake -S . -B %BUILD_DIR% -A %VENDOR_WINDOWS_ARCH% -DSDL_STATIC=ON -DSDL_SHARED=OFF -DSDL_VULKAN=ON -DBUILD_SHARED_LIBS=OFF -DSDLIMAGE_AVIF=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded
if errorlevel 1 exit /b 1
findstr /X /C:"SDL_VULKAN:BOOL=ON" %BUILD_DIR%\CMakeCache.txt >nul
if errorlevel 1 (
   echo ERROR: SDL Vulkan support is disabled in %BUILD_DIR%\CMakeCache.txt
   exit /b 1
)
cmake --build %BUILD_DIR% -j%NUMBER_OF_PROCESSORS% --config Release
if errorlevel 1 exit /b 1

if not exist %output_dir% mkdir %output_dir%
if not exist image\%output_dir% mkdir image\%output_dir%
if not exist mixer\%output_dir% mkdir mixer\%output_dir%
if not exist ttf\%output_dir% mkdir ttf\%output_dir%

copy /y %BUILD_DIR%\SDL\Release\SDL3-static.lib             %output_dir%\SDL3_static.lib
copy /y %BUILD_DIR%\SDL_image\Release\SDL3_image-static.lib image\%output_dir%\SDL3_image_static.lib
copy /y %BUILD_DIR%\SDL_mixer\Release\SDL3_mixer-static.lib mixer\%output_dir%\SDL3_mixer_static.lib
copy /y %BUILD_DIR%\SDL_ttf\Release\SDL3_ttf-static.lib     ttf\%output_dir%\SDL3_ttf_static.lib
