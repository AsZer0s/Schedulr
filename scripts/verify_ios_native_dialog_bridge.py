#!/usr/bin/env python3
"""Verify the static contract of the app-owned iOS UIKit dialog bridge."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBXPROJ = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"
APP_DELEGATE = ROOT / "ios" / "Runner" / "AppDelegate.swift"
PLUGIN = ROOT / "ios" / "Runner" / "NativeDialogPlugin.swift"
TESTS = ROOT / "ios" / "RunnerTests" / "RunnerTests.swift"
RUNNER_ENTITLEMENTS = ROOT / "ios" / "Runner" / "Runner.entitlements"

RUNNER_SOURCES_ID = "97C146EA1CF9000F007C117D"
WIDGET_SOURCES_ID = "A10000000000000000000014"
PLUGIN_BUILD_FILE_ID = "B7A100000000000000000001"
PLUGIN_FILE_ID = "B7A100000000000000000002"

errors: list[str] = []
checks: list[str] = []


def require(condition: bool, message: str) -> None:
    (checks if condition else errors).append(message)


def object_block(text: str, object_id: str) -> str:
    match = re.search(rf"^\s*{re.escape(object_id)}(?: /\*.*?\*/)? = \{{", text, re.MULTILINE)
    if not match:
        return ""
    depth = 0
    opened = False
    for index in range(match.end() - 1, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
            opened = True
        elif char == "}":
            depth -= 1
            if opened and depth == 0:
                semicolon = text.find(";", index)
                return text[match.start() : semicolon + 1]
    return ""


for path in (PBXPROJ, APP_DELEGATE, PLUGIN, TESTS, RUNNER_ENTITLEMENTS):
    require(path.is_file(), f"{path.relative_to(ROOT)} exists")

if not all(path.is_file() for path in (PBXPROJ, APP_DELEGATE, PLUGIN, TESTS, RUNNER_ENTITLEMENTS)):
    print("iOS native dialog bridge verification FAILED")
    for error in errors:
        print(f"  FAIL: {error}")
    raise SystemExit(1)

pbx = PBXPROJ.read_text()
app_delegate = APP_DELEGATE.read_text()
plugin = PLUGIN.read_text()
tests = TESTS.read_text()
runner_sources = object_block(pbx, RUNNER_SOURCES_ID)
widget_sources = object_block(pbx, WIDGET_SOURCES_ID)
runner_entitlements = RUNNER_ENTITLEMENTS.read_text()

require(
    "keychain-access-groups" in runner_entitlements
    and "$(AppIdentifierPrefix)app.schedulr.schedulr" in runner_entitlements,
    "Runner enables device-bound Keychain access for saved account identifiers",
)
require(
    "func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge)" in app_delegate,
    "AppDelegate registers plugins from didInitializeImplicitFlutterEngine",
)
require(
    "NativeDialogPlugin.register(with: engineBridge.pluginRegistry)" in app_delegate,
    "AppDelegate passes the implicit engine registry to the app-owned plugin",
)
require(
    "guard let registrar = registry.registrar(forPlugin: pluginKey) else { return }" in plugin
    and "register(with: registrar)" in plugin,
    "optional implicit-engine registrar is safely unwrapped before registration",
)
require(
    'static let channelName = "app.schedulr/native_dialogs"' in plugin,
    "source documents the exact Dart channel name",
)
require(
    "binaryMessenger: registrar.messenger()" in plugin,
    "method channel uses the implicit engine registrar messenger",
)
require(
    all(f"case {name}" in plugin for name in ("showActionSheet", "showConfirmation", "showTextInput")),
    "all typed Dart method names are implemented",
)
require(
    all(field in plugin for field in ("confirmLabel", "cancelLabel", "initialValue", "placeholder", "maxLength", "destructive")),
    "all dialog contract fields are decoded",
)
require("UIAlertController" in plugin and "UIAlertAction" in plugin, "bridge uses system UIKit alerts and actions")
require("DispatchQueue.main.async" in plugin and "Thread.isMainThread" in plugin, "UIKit work is marshalled to the main thread")
require("activePresentation == nil" in plugin, "overlapping dialog presentations are rejected")
require("foregroundActive" in plugin and "UIWindowScene" in plugin and "isKeyWindow" in plugin, "presenter is found from an active UIWindowScene")
require("presentedViewController" in plugin and "visibleViewController" in plugin and "selectedViewController" in plugin, "top-most container and presented controllers are traversed")
require("popover.sourceView" in plugin and "popover.sourceRect" in plugin, "action sheet popover anchor is configured for iPad")
require("UIAdaptivePresentationControllerDelegate" in plugin and "presentationControllerDidDismiss" in plugin, "outside/adaptive dismissal resolves cancellation")
require("private var result: FlutterResult?" in plugin and "self.result = nil" in plugin, "FlutterResult is guarded for exactly-once completion")
require("case .confirmed: result(true)" in plugin, "confirmation returns boolean true")
require("case .cancelled: result(nil)" in plugin, "cancellation returns null")
require("NativeDialogTextLengthLimiter" in plugin and "markedTextRange" in plugin, "maxLength handles normal and composed text entry")
require(
    all(code in plugin for code in ("invalid_arguments", "presentation_in_progress", "presentation_unavailable", "presentation_failed")),
    "bridge exposes stable typed Flutter error codes",
)

require(PLUGIN_BUILD_FILE_ID in runner_sources, "NativeDialogPlugin.swift is in the Runner Sources phase")
require(PLUGIN_BUILD_FILE_ID not in widget_sources and PLUGIN_FILE_ID not in widget_sources, "NativeDialogPlugin.swift is excluded from the widget Sources phase")
require("NativeDialogPlugin.swift in Sources" not in widget_sources, "widget target has no native dialog source entry")

require("testActionSheetRequestParsesStableIDsAndDestructiveFlags" in tests, "XCTest covers action decoding")
require("testInvalidArgumentsProduceTypedError" in tests, "XCTest covers typed invalid arguments")
require("testTextInputFactoryConfiguresFieldAndLimitsInitialValue" in tests, "XCTest covers text input setup")
require("testPresentationSessionResolvesFlutterResultExactlyOnce" in tests, "XCTest covers exactly-once results")
require("testAdaptiveDismissalResolvesCancellationExactlyOnce" in tests, "XCTest covers popover/adaptive cancellation")

if errors:
    print(f"iOS native dialog bridge verification FAILED: {len(errors)} issue(s)")
    for error in errors:
        print(f"  FAIL: {error}")
    print(f"  Passed checks before failure: {len(checks)}")
    raise SystemExit(1)

print(f"iOS native dialog bridge verification PASSED: {len(checks)} checks")
for check in checks:
    print(f"  OK: {check}")
