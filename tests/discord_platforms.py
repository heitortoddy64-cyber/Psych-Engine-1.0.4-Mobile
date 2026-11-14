#!/usr/bin/env python3
"""Check the real Discord XML conditions with Lime and type-check the disabled module.

Requires Haxe, Neko and Lime. This is an isolated platform configuration test,
not a full engine or Android APK build.
"""

import argparse
from pathlib import Path
import re
import subprocess
import tempfile


def run(command, cwd):
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, timeout=60)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    source = args.source_root
    project = (source / "Project.xml").read_text()
    declarations = []
    for tag, name in [("define", "DISCORD_ALLOWED"), ("haxelib", "hxdiscord_rpc")]:
        matches = re.findall(rf'<{tag}\s+name="{name}"[^>]*?/>', project)
        assert len(matches) == 1, f"Expected one {name} declaration"
        declarations.append(matches[0])

    with tempfile.TemporaryDirectory(prefix="psych-discord-platforms-") as directory:
        root = Path(directory)
        backend = root / "source/backend"
        backend.mkdir(parents=True)
        # Preserve the actual preprocessor guards and all Discord implementation code.
        (backend / "Discord.hx").write_text((source / "source/backend/Discord.hx").read_text())
        (root / "source/Smoke.hx").write_text("class Smoke { static function main() {} }")
        fixture = root / "Project.xml"
        fixture.write_text(
            '<project><app main="Smoke" file="Smoke"/><classpath name="source"/>'
            + "".join(declarations) + "</project>"
        )

        for target in ["android", "ios", "html5"]:
            result = run(["haxelib", "run", "lime", "display", str(fixture), target, "-release", "-nocolor"], root)
            assert result.returncode == 0, f"{target}: {result.stdout}{result.stderr}"
            hxml = result.stdout
            assert "DISCORD_ALLOWED" not in hxml and "hxdiscord_rpc" not in hxml, target
            if target == "android":
                assert "-D android" in hxml and "-D mobile" in hxml, hxml
            output = root / f"{target}.hxml"
            output.write_text(hxml)
            result = run([
                "haxe", str(output), "--no-output", "--macro",
                'haxe.macro.Context.getModule("backend.Discord")',
            ], root)
            assert result.returncode == 0, f"{target}: {result.stdout}{result.stderr}"
            print(f"PASS: {target} excludes Discord and type-checks the guarded module")

        for target in ["linux", "windows", "mac"]:
            result = run(["haxelib", "run", "lime", "display", str(fixture), target, "-release", "-nocolor"], root)
            combined = result.stdout + result.stderr
            if result.returncode:
                # Without the optional desktop library installed, resolution must
                # explicitly request it. No other project libraries are in the fixture.
                assert 'Could not find haxelib "hxdiscord_rpc"' in combined, combined
            else:
                assert "DISCORD_ALLOWED" in result.stdout and "hxdiscord_rpc" in result.stdout, combined
            print(f"PASS: {target} retains the desktop Discord dependency")


if __name__ == "__main__":
    main()
