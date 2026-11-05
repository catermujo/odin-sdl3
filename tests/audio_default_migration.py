import argparse
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-out", type=Path, required=True)
    args = parser.parse_args()
    sdk = Path(__file__).resolve().parents[1]
    output = args.out.resolve()
    output.mkdir(parents=True, exist_ok=True)
    # DUMBAI: Build SDL from source so stale vendor binaries cannot hide a migration regression.
    (output / "CMakeLists.txt").write_text(
        "cmake_minimum_required(VERSION 3.16)\n"
        "project(audio-default-migration C)\n"
        'set(SDL_SHARED OFF CACHE BOOL "" FORCE)\n'
        'set(SDL_STATIC ON CACHE BOOL "" FORCE)\n'
        'set(SDL_DUMMYAUDIO ON CACHE BOOL "" FORCE)\n'
        'if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")\n'
        "  add_compile_options(-fsanitize=address -fno-omit-frame-pointer -UNDEBUG)\n"
        "  add_link_options(-fsanitize=address)\n"
        "endif()\n"
        f'add_subdirectory("{sdk / "SDL"}" sdl)\n'
        f'add_executable(audio-default-migration "{sdk / "tests/audio_default_migration.c"}")\n'
        "target_link_libraries(audio-default-migration PRIVATE SDL3::SDL3-static)\n"
    )
    subprocess.run(
        ["cmake", "-S", str(output), "-B", str(output / "build")],
        check=True,
    )
    subprocess.run(
        [
            "cmake",
            "--build",
            str(output / "build"),
            "--config",
            "Debug",
            "--parallel",
            "8",
        ],
        check=True,
    )
    executable = output / "build/audio-default-migration"
    if not executable.exists():
        executable = output / "build/Debug/audio-default-migration.exe"
    subprocess.run([str(executable)], check=True, timeout=30)


if __name__ == "__main__":
    main()
