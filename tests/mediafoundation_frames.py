import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-source", type=Path)
    parser.add_argument("-guard-only", action="store_true")
    args = parser.parse_args()
    sdk = Path(__file__).resolve().parents[1]
    source = (
        args.source
        or sdk / "SDL/src/camera/mediafoundation/SDL_camera_mediafoundation.c"
    )
    code = source.read_text()
    start = code.index("static SDL_CameraFrameResult MEDIAFOUNDATION_CopyFrame(")
    end = code.index("\n#endif", start)
    interfaces = re.findall(
        r"^static const IID SDL_IID_IMF2DBuffer2? = .*;$", code, re.M
    )
    vswhere = (
        Path(os.environ["ProgramFiles(x86)"])
        / "Microsoft Visual Studio/Installer/vswhere.exe"
    )
    installation = subprocess.check_output(
        [
            str(vswhere),
            "-latest",
            "-requires",
            "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
            "-property",
            "installationPath",
        ],
        text=True,
    ).strip()
    vcvars = Path(installation) / "VC/Auxiliary/Build/vcvars64.bat"
    with tempfile.TemporaryDirectory(prefix="sdl-mediafoundation-") as directory:
        work = Path(directory)
        header = code[: code.index('#include "SDL_internal.h"')]
        (work / "mediafoundation_backend.h").write_text(
            header + "\n".join(interfaces) + "\n" + code[start:end]
        )
        executable = work / "frames.exe"
        batch = work / "build.bat"
        batch.write_text(
            f'@call "{vcvars}" >nul\n'
            f'@cl /nologo /std:c11 /Od /W4 /I"{sdk / "SDL/include"}" /I"{work}" '
            f'"{sdk / "tests/mediafoundation_frames.c"}" /Fe:"{executable}" '
            f'/Fo:"{work / "frames.obj"}" /link "{sdk / "windows_x64/SDL3.lib"}" mfplat.lib ole32.lib\n'
        )
        subprocess.run(["cmd", "/d", "/c", str(batch)], cwd=work, check=True)
        env = os.environ | {
            "PATH": str(sdk / "windows_x64") + os.pathsep + os.environ["PATH"]
        }
        result = subprocess.run(
            [str(executable), *(["guard"] if args.guard_only else [])], env=env
        )
        print(f"frame regression exit: 0x{result.returncode & 0xFFFFFFFF:08x}")
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
