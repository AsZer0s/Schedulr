#!/usr/bin/env python3
"""Validate signed Runner/Widget entitlements in an exported iOS IPA."""

from __future__ import annotations

import plistlib
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

APP_GROUP = "group.app.schedulr.shared"
APP_BUNDLE = "app.schedulr.schedulr"
WIDGET_BUNDLE = "app.schedulr.schedulr.widget"


def command(*args: str) -> str:
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT)


def codesign_entitlements(path: Path) -> dict:
    output = command("codesign", "-d", "--entitlements", "-", str(path))
    start = output.find("<?xml")
    if start < 0:
        raise RuntimeError(f"no signed entitlements found for {path}")
    return plistlib.loads(output[start:].encode())


def bundle_id(path: Path) -> str:
    info = plistlib.loads((path / "Info.plist").read_bytes())
    return info.get("CFBundleIdentifier", "")


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} SIGNED.ipa", file=sys.stderr)
        return 2
    ipa = Path(sys.argv[1])
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        with zipfile.ZipFile(ipa) as archive:
            archive.extractall(root)
        app = root / "Payload" / "Runner.app"
        widget = app / "PlugIns" / "SchedulrWidget.appex"
        if not app.is_dir() or not widget.is_dir():
            raise RuntimeError("Runner.app or embedded Widget Extension is missing")
        if bundle_id(app) != APP_BUNDLE or bundle_id(widget) != WIDGET_BUNDLE:
            raise RuntimeError("unexpected Runner/Widget bundle identifier")
        app_entitlements = codesign_entitlements(app)
        widget_entitlements = codesign_entitlements(widget)
        app_groups = app_entitlements.get("com.apple.security.application-groups", [])
        widget_groups = widget_entitlements.get("com.apple.security.application-groups", [])
        if APP_GROUP not in app_groups or APP_GROUP not in widget_groups:
            raise RuntimeError("both signed targets must authorize the shared App Group")
        app_team = app_entitlements.get("com.apple.developer.team-identifier")
        widget_team = widget_entitlements.get("com.apple.developer.team-identifier")
        if not app_team or app_team != widget_team:
            raise RuntimeError("Runner and Widget must use the same signing team")
        command("codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app))
        print(f"Signed IPA verified: team={app_team}, app-group={APP_GROUP}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        print(f"signed iOS IPA verification FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
