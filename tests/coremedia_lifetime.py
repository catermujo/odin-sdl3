import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-source", type=Path)
    parser.add_argument("-out", type=Path, required=True)
    parser.add_argument("-expect-use-after-free", action="store_true")
    args = parser.parse_args()
    sdk = Path(__file__).resolve().parents[1]
    source = args.source or sdk / "SDL/src/camera/coremedia/SDL_camera_coremedia.m"
    code = source.read_text()
    start = code.index("@class SDLCaptureVideoDataOutputSampleBufferDelegate;")
    end = code.index("static bool COREMEDIA_WaitDevice", start)
    close_start = code.index("static void COREMEDIA_CloseDevice(")
    close_end = code.index("static bool COREMEDIA_OpenDevice(", close_start)
    layout = (sdk / "SDL/src/camera/SDL_syscamera.h").read_text()
    layout_start = layout.index("typedef enum SDL_CameraFrameResult")
    layout_end = layout.index("typedef struct SDL_CameraDriverImpl", layout_start)
    output = args.out.resolve()
    output.mkdir(parents=True, exist_ok=True)
    (output / "coremedia_backend.h").write_text(
        code[start:end] + "\n" + code[close_start:close_end]
    )
    (output / "camera_layout.h").write_text(layout[layout_start:layout_end])
    executable = output / "coremedia-lifetime"
    command = [
        "clang",
        "-x",
        "objective-c",
        "-fobjc-arc",
        "-fblocks",
        "-fsanitize=address",
        "-fno-omit-frame-pointer",
        "-g",
        "-O1",
        "-I",
        str(sdk / "SDL/include"),
        "-I",
        str(sdk / "include"),
        "-I",
        str(output),
        str(sdk / "tests/coremedia_lifetime.m"),
        "-x",
        "none",
        str(sdk / "darwin_arm64/libSDL3.0.dylib"),
        f"-Wl,-rpath,{sdk / 'darwin_arm64'}",
        "-framework",
        "Foundation",
        "-framework",
        "AVFoundation",
        "-framework",
        "CoreMedia",
        "-o",
        str(executable),
    ]
    build = subprocess.run(command, capture_output=True, text=True, check=False)
    (output / "build.log").write_text(build.stdout + build.stderr)
    (output / "command.json").write_text(json.dumps(command, indent=2) + "\n")
    assert build.returncode == 0, build.stderr
    result = subprocess.run(
        [str(executable)],
        capture_output=True,
        text=True,
        timeout=15,
        env=os.environ | {"ASAN_OPTIONS": "detect_leaks=0:abort_on_error=1"},
        check=False,
    )
    (output / "stdout.log").write_text(result.stdout)
    (output / "stderr.log").write_text(result.stderr)
    use_after_free = "heap-use-after-free" in result.stderr
    report = {
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "executable_sha256": hashlib.sha256(executable.read_bytes()).hexdigest(),
        "exit": result.returncode,
        "use_after_free": use_after_free,
        "expected_use_after_free": args.expect_use_after_free,
    }
    (output / "result.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    if args.expect_use_after_free:
        assert result.returncode != 0 and use_after_free, result.stderr
    else:
        assert result.returncode == 0, result.stderr
        assert "late callback safely ignored" in result.stdout
        assert "contended callback does not block teardown" in result.stdout
        assert "inflight callback completes before state is freed" in result.stdout


if __name__ == "__main__":
    main()
