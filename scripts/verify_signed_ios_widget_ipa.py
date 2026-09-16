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
INTENT_BUNDLE = "app.schedulr.schedulr.intents"


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
        intent = app / "PlugIns" / "SchedulrIntentExtension.appex"
        if not app.is_dir() or not widget.is_dir() or not intent.is_dir():
            raise RuntimeError("Runner.app, Widget, or Intent extension is missing")
        if {bundle_id(app), bundle_id(widget), bundle_id(intent)} != {APP_BUNDLE, WIDGET_BUNDLE, INTENT_BUNDLE}:
            raise RuntimeError("unexpected Runner/Widget/Intent bundle identifier")
        app_entitlements = codesign_entitlements(app)
        widget_entitlements = codesign_entitlements(widget)
        intent_entitlements = codesign_entitlements(intent)
        app_groups = app_entitlements.get("com.apple.security.application-groups", [])
        widget_groups = widget_entitlements.get("com.apple.security.application-groups", [])
        intent_groups = intent_entitlements.get("com.apple.security.application-groups", [])
        if any(APP_GROUP not in groups for groups in (app_groups, widget_groups, intent_groups)):
            raise RuntimeError("all signed targets must authorize the shared App Group")
        teams = {
            codesign_entitlements(path).get("com.apple.developer.team-identifier")
            for path in (app, widget, intent)
        }
        if len(teams) != 1 or None in teams:
            raise RuntimeError("Runner, Widget, and Intent must use the same signing team")
        signed = [app, widget, intent]
        for path in signed:
            command("codesign", "--verify", "--strict", "--verbose=2", str(path))
        print(f"Signed IPA verified: team={next(iter(teams))}, app-group={APP_GROUP}, extensions=2")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        print(f"signed iOS IPA verification FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
