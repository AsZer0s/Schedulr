#!/usr/bin/env python3
"""Validate the static structure of the iOS Schedulr WidgetKit integration."""

from __future__ import annotations

import plistlib
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "ios"
PBXPROJ = IOS / "Runner.xcodeproj" / "project.pbxproj"
SCHEME = IOS / "Runner.xcodeproj" / "xcshareddata" / "xcschemes" / "Runner.xcscheme"
WORKFLOW = ROOT / ".github" / "workflows" / "tag-release.yml"
RUNNER_INFO = IOS / "Runner" / "Info.plist"
RUNNER_ENTITLEMENTS = IOS / "Runner" / "Runner.entitlements"
WIDGET_DIR = IOS / "SchedulrWidget"
WIDGET_SWIFT = WIDGET_DIR / "SchedulrWidget.swift"
WIDGET_INFO = WIDGET_DIR / "Info.plist"
WIDGET_ENTITLEMENTS = WIDGET_DIR / "SchedulrWidget.entitlements"
FLUTTER_DEBUG_XCCONFIG = IOS / "Flutter" / "Debug.xcconfig"
FLUTTER_RELEASE_XCCONFIG = IOS / "Flutter" / "Release.xcconfig"
SETTINGS_PAGE = ROOT / "lib" / "features" / "settings" / "presentation" / "settings_page.dart"
INTENT_DEF = WIDGET_DIR / "SelectTimetable.intentdefinition"
INTENT_DIR = IOS / "SchedulrIntentExtension"
INTENT_SWIFT = INTENT_DIR / "IntentHandler.swift"
INTENT_INFO = INTENT_DIR / "Info.plist"
INTENT_ENTITLEMENTS = INTENT_DIR / "SchedulrIntentExtension.entitlements"
SIGNED_IPA_VERIFIER = ROOT / "scripts" / "verify_signed_ios_widget_ipa.py"
APP_GROUP = "group.app.schedulr.shared"
SNAPSHOT_KEY = "schedulr.widget.snapshot.v1"
CATALOG_KEY = "schedulr.widget.snapshot.v2"
WIDGET_BUNDLE = "app.schedulr.schedulr.widget"
WIDGET_TARGET_ID = "A10000000000000000000010"
WIDGET_PRODUCT_ID = "A10000000000000000000008"
EMBED_PHASE_ID = "A1000000000000000000000A"
THIN_PHASE_ID = "3B06AD1E1E4923F5004D2608"
INTENT_TARGET_ID = "B10000000000000000000010"
INTENT_PRODUCT_ID = "B10000000000000000000006"
INTENT_BUNDLE = "app.schedulr.schedulr.intents"

errors: list[str] = []
checks: list[str] = []


def require(condition: bool, message: str) -> None:
    if condition:
        checks.append(message)
    else:
        errors.append(message)


def load_plist(path: Path) -> dict:
    try:
        with path.open("rb") as handle:
            value = plistlib.load(handle)
        require(isinstance(value, dict), f"{path.relative_to(ROOT)} is a plist dictionary")
        return value if isinstance(value, dict) else {}
    except Exception as exc:  # pragma: no cover - command line diagnostic
        errors.append(f"cannot parse {path.relative_to(ROOT)}: {exc}")
        return {}


def object_block(text: str, object_id: str) -> str:
    match = re.search(rf"^\s*{re.escape(object_id)}(?: /\*.*?\*/)? = \{{", text, re.MULTILINE)
    if not match:
        return ""
    start = match.start()
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
                return text[start : semicolon + 1]
    return ""


for path in [PBXPROJ, SCHEME, WORKFLOW, RUNNER_INFO, RUNNER_ENTITLEMENTS, WIDGET_SWIFT, WIDGET_INFO, WIDGET_ENTITLEMENTS, FLUTTER_DEBUG_XCCONFIG, FLUTTER_RELEASE_XCCONFIG, SETTINGS_PAGE, SIGNED_IPA_VERIFIER, INTENT_DEF, INTENT_SWIFT, INTENT_INFO, INTENT_ENTITLEMENTS]:
    require(path.is_file(), f"{path.relative_to(ROOT)} exists")

if not PBXPROJ.is_file():
    print("FAIL: project.pbxproj is missing", file=sys.stderr)
    raise SystemExit(1)

pbx = PBXPROJ.read_text()
scheme = SCHEME.read_text() if SCHEME.is_file() else ""
workflow = WORKFLOW.read_text() if WORKFLOW.is_file() else ""
swift = WIDGET_SWIFT.read_text() if WIDGET_SWIFT.is_file() else ""
flutter_debug_xcconfig = FLUTTER_DEBUG_XCCONFIG.read_text() if FLUTTER_DEBUG_XCCONFIG.is_file() else ""
flutter_release_xcconfig = FLUTTER_RELEASE_XCCONFIG.read_text() if FLUTTER_RELEASE_XCCONFIG.is_file() else ""
settings_page = SETTINGS_PAGE.read_text() if SETTINGS_PAGE.is_file() else ""
intent_definition_text = INTENT_DEF.read_text() if INTENT_DEF.is_file() else ""

runner_info = load_plist(RUNNER_INFO) if RUNNER_INFO.is_file() else {}
runner_entitlements = load_plist(RUNNER_ENTITLEMENTS) if RUNNER_ENTITLEMENTS.is_file() else {}
widget_info = load_plist(WIDGET_INFO) if WIDGET_INFO.is_file() else {}
widget_entitlements = load_plist(WIDGET_ENTITLEMENTS) if WIDGET_ENTITLEMENTS.is_file() else {}
intent_swift = INTENT_SWIFT.read_text() if INTENT_SWIFT.is_file() else ""
intent_def = load_plist(INTENT_DEF) if INTENT_DEF.is_file() else {}
intent_info = load_plist(INTENT_INFO) if INTENT_INFO.is_file() else {}
intent_entitlements = load_plist(INTENT_ENTITLEMENTS) if INTENT_ENTITLEMENTS.is_file() else {}

# pbxproj object IDs may be referenced many times; only object declarations must be unique.
declared_ids = re.findall(r"^\t\t([0-9A-F]{24})(?: /\*.*?\*/)? = \{", pbx, re.MULTILINE)
duplicate_declarations = sorted(object_id for object_id, count in Counter(declared_ids).items() if count > 1)
require(not duplicate_declarations, f"pbxproj object declarations are unique ({duplicate_declarations or 'ok'})")

all_referenced_ids = set(re.findall(r"\b[0-9A-F]{24}\b", pbx))
declared_id_set = set(declared_ids)
allowed_non_object_ids = {
    "97C146E61CF9000F007C117D",  # root object is also declared; retained for clarity
}
missing_declarations = sorted(all_referenced_ids - declared_id_set - allowed_non_object_ids)
require(not missing_declarations, f"pbxproj object references resolve ({missing_declarations or 'ok'})")

widget_target = object_block(pbx, WIDGET_TARGET_ID)
runner_target = object_block(pbx, "97C146ED1CF9000F007C117D")
embed_phase = object_block(pbx, EMBED_PHASE_ID)
widget_product = object_block(pbx, WIDGET_PRODUCT_ID)
widget_dependency = object_block(pbx, "A10000000000000000000012")
widget_sources = object_block(pbx, "A10000000000000000000014")
widget_frameworks = object_block(pbx, "A1000000000000000000000E")
widget_config_list = object_block(pbx, "A10000000000000000000013")
intent_target = object_block(pbx, INTENT_TARGET_ID)
intent_product = object_block(pbx, INTENT_PRODUCT_ID)
intent_sources = object_block(pbx, "B10000000000000000000014")
intent_resources = object_block(pbx, "B10000000000000000000015")

require('name = SchedulrIntentExtension;' in intent_target, "Intent extension target exists")
require(INTENT_PRODUCT_ID in intent_target and 'wrapper.app-extension' in intent_product, "Intent extension product reference is valid")
require('INTENTS_CODEGEN_LANGUAGE = Swift' in intent_target or 'INTENTS_CODEGEN_LANGUAGE = Swift' in pbx, "Intent extension enables Swift intent code generation")
require('information' in intent_definition_text and '<string>View</string>' in intent_definition_text, "Intent definition uses Xcode-valid information/View category")
require('SelectTimetable.intentdefinition in Resources' in intent_resources, "Intent definition is in Resources phase")
require(INTENT_TARGET_ID in pbx[pbx.find("targets = (") : pbx.find(");", pbx.find("targets = ("))], "project target list includes Intent extension")
require(INTENT_BUNDLE in pbx, "Intent extension bundle identifier is configured")
require('BlueprintIdentifier = "B10000000000000000000010"' in scheme and 'BuildableName = "SchedulrIntentExtension.appex"' in scheme, "shared Runner scheme references Intent extension")
require('IntentTimelineProvider' in swift and 'IntentConfiguration' in swift, "widget uses iOS 15 IntentConfiguration")
require(CATALOG_KEY in swift and 'configuration.timetable?.identifier' in swift, "widget reads selected timetable from Catalog")
require('provideTimetableOptionsCollection' in intent_swift and 'timetableId' in intent_swift, "Intent handler supplies local timetable options")
require(APP_GROUP in intent_entitlements.get("com.apple.security.application-groups", []), "Intent extension entitlement contains the App Group")
require('productType = "com.apple.product-type.app-extension";' in widget_target, "widget target is an app extension")
require(WIDGET_PRODUCT_ID in widget_target, "widget target references its appex product")
require('explicitFileType = "wrapper.app-extension";' in widget_product and 'path = SchedulrWidget.appex;' in widget_product, "SchedulrWidget.appex product reference is valid")
require(WIDGET_TARGET_ID in pbx[pbx.find("targets = (") : pbx.find(");", pbx.find("targets = ("))], "project target list includes SchedulrWidget")
require('dstSubfolderSpec = 13;' in embed_phase, "Embed App Extensions uses PlugIns destination")
require('SchedulrWidget.appex in Embed App Extensions' in embed_phase, "Embed App Extensions embeds SchedulrWidget.appex")
require('target = A10000000000000000000010 /* SchedulrWidget */;' in widget_dependency, "Runner has target dependency on SchedulrWidget")
require('A10000000000000000000012 /* PBXTargetDependency */' in runner_target, "Runner target lists widget dependency")
require('SchedulrWidget.swift in Sources' in widget_sources, "widget Swift source is in widget Sources phase")
require('WidgetKit.framework in Frameworks' in widget_frameworks, "widget links WidgetKit.framework")
require('SwiftUI.framework in Frameworks' in widget_frameworks, "widget links SwiftUI.framework")
require('Flutter' not in widget_target + widget_sources + widget_frameworks, "widget target does not link Flutter")
require(all(name in widget_config_list for name in ["Debug", "Release", "Profile"]), "widget has Debug/Profile/Release configurations")
require('#include "Generated.xcconfig"' in flutter_debug_xcconfig, "Flutter Debug.xcconfig imports generated Flutter build variables")
require('#include "Generated.xcconfig"' in flutter_release_xcconfig, "Flutter Release.xcconfig imports generated Flutter build variables")

for config_id, name in [
    ("A10000000000000000000016", "Debug"),
    ("A10000000000000000000017", "Release"),
    ("A10000000000000000000018", "Profile"),
]:
    config = object_block(pbx, config_id)
    require(f"name = {name};" in config, f"widget {name} configuration exists")
    require('PRODUCT_BUNDLE_IDENTIFIER = app.schedulr.schedulr.widget;' in config, f"widget {name} bundle identifier is correct")
    require('IPHONEOS_DEPLOYMENT_TARGET = 15.0;' in config, f"widget {name} deployment target is iOS 15")
    require('INFOPLIST_FILE = SchedulrWidget/Info.plist;' in config, f"widget {name} Info.plist is configured")
    require('CODE_SIGN_ENTITLEMENTS = SchedulrWidget/SchedulrWidget.entitlements;' in config, f"widget {name} entitlements are configured")
    require('APPLICATION_EXTENSION_API_ONLY = YES;' in config, f"widget {name} enforces extension-safe APIs")
    require('SKIP_INSTALL = YES;' in config, f"widget {name} uses SKIP_INSTALL")
    require('CURRENT_PROJECT_VERSION = 15;' in config, f"widget {name} has a non-empty default build number")
    require('MARKETING_VERSION = 1.1.15;' in config, f"widget {name} has a non-empty default marketing version")
    expected_base = "9740EEB21CF90195004384FC" if name == "Debug" else "7AFA3C8E1D35360C0083082E"
    require(f"baseConfigurationReference = {expected_base}" in config, f"widget {name} inherits Flutter-generated version settings")

for config_id, name in [
    ("97C147061CF9000F007C117D", "Debug"),
    ("97C147071CF9000F007C117D", "Release"),
    ("249021D4217E4FDB00AE95B9", "Profile"),
]:
    config = object_block(pbx, config_id)
    require('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' in config, f"Runner {name} entitlements are configured")

phase_ids = re.findall(r"([0-9A-F]{24}) /\*.*?\*/,", runner_target)
require(EMBED_PHASE_ID in phase_ids and THIN_PHASE_ID in phase_ids, "Runner includes Embed App Extensions and Thin Binary phases")
if EMBED_PHASE_ID in phase_ids and THIN_PHASE_ID in phase_ids:
    require(phase_ids.index(EMBED_PHASE_ID) < phase_ids.index(THIN_PHASE_ID), "Thin Binary runs after Embed App Extensions")

require(f'BlueprintIdentifier = "{WIDGET_TARGET_ID}"' in scheme, "shared Runner scheme builds SchedulrWidget")
require('BuildableName = "SchedulrWidget.appex"' in scheme, "shared scheme references widget appex")

require(widget_info.get("NSExtension", {}).get("NSExtensionPointIdentifier") == "com.apple.widgetkit-extension", "widget Info.plist declares WidgetKit extension point")
require(widget_info.get("CFBundlePackageType") == "XPC!", "widget Info.plist uses XPC bundle type")
require(runner_info.get("CFBundleShortVersionString") == "$(FLUTTER_BUILD_NAME)", "Runner Info.plist uses FLUTTER_BUILD_NAME")
require(runner_info.get("CFBundleVersion") == "$(FLUTTER_BUILD_NUMBER)", "Runner Info.plist uses FLUTTER_BUILD_NUMBER")
require(widget_info.get("CFBundleShortVersionString") == "$(MARKETING_VERSION)", "widget Info.plist uses target marketing version")
require(widget_info.get("CFBundleVersion") == "$(CURRENT_PROJECT_VERSION)", "widget Info.plist uses target build version")
require(APP_GROUP in runner_entitlements.get("com.apple.security.application-groups", []), "Runner entitlement contains the App Group")
require(APP_GROUP in widget_entitlements.get("com.apple.security.application-groups", []), "widget entitlement contains the App Group")

schemes = [
    scheme_name
    for url_type in runner_info.get("CFBundleURLTypes", [])
    for scheme_name in url_type.get("CFBundleURLSchemes", [])
]
require("schedulr" in schemes, "Runner Info.plist registers the schedulr URL scheme")

require(('StaticConfiguration' in swift or 'IntentConfiguration' in swift) and 'TimelineProvider' in swift, "widget uses a supported WidgetKit configuration and timeline provider")
require(APP_GROUP in swift and SNAPSHOT_KEY in swift, "widget reads the agreed App Group snapshot key")
require('schedulr://home?homeWidget' in swift, "widget click URL is configured")
require(all(family in swift for family in [".systemSmall", ".systemMedium", ".systemLarge"]), "widget supports small, medium, and large families")
require("home_widget" not in swift.lower(), "widget source does not import or reference home_widget")
imports = set(re.findall(r"^import\s+(\w+)", swift, re.MULTILINE))
require(imports <= {"Foundation", "Intents", "SwiftUI", "WidgetKit"}, f"widget imports only extension-safe frameworks ({sorted(imports)})")
require("lineLimit(2)" in swift, "course titles/details include two-line adaptation")
require(all(field in swift for field in ["timetableName", "semesterName", "teachingWeek", "weekday", "startPeriod", "endPeriod", "color"]), "widget parser covers the Flutter snapshot schema fields")
require('keys: ["id", "sessionId", "courseId"]' in swift, "widget uses unique sessionId before courseId for SwiftUI identity")
require('value(root, keys: ["futureDays"]) as? [Any]' in swift, "widget parses futureDays")
require('func selectedDay(at date: Date) -> DayProjection?' in swift and 'calendar.isDate($0.date, inSameDayAs: date)' in swift, "widget dynamically selects the snapshot day matching each entry date")
require('let current = snapshot.currentCourse(in: selectedDay, at: entry.date)' in swift and 'let next = snapshot.nextCourse(in: selectedDay, at: entry.date)' in swift, "view recomputes current and next from the selected day at entry.date")
require('guard let start = course.start, let end = course.end else { return false }' in swift and 'return start <= date && date < end' in swift, "current course uses half-open parsed time bounds")
require('let ongoing = bool(' not in swift and '.ongoing' not in swift, "stored ongoing flags are ignored")
require('value(root, keys: ["next", "nextCourse"])' not in swift and 'currentCourse"]' not in swift, "stored root current/next projections are ignored")
weekday_cases = {
    1: "周日",
    2: "周一",
    3: "周二",
    4: "周三",
    5: "周四",
    6: "周五",
    7: "周六",
}
require(all(f'case {number}: return "{label}"' in swift for number, label in weekday_cases.items()), "calendar weekday mapping explicitly covers 周一..周日")
require('selectedDay.teachingWeek == nil' in swift and 'case .noData:' in swift, "outside-semester is selected-day teachingWeek nil while noTimetable remains noData")
require('selectedDay.dateText' in swift and 'selectedDay.weekText' in swift and 'selectedDay.courses.prefix(3)' in swift, "widget displays selected date, teaching week, and course list")
require('snapshot.nextDaySummary(after: selectedDay)' in swift and 'nextDay(after day: DayProjection)' in swift, "widget derives the next-day summary from the selected day")
require('func fallbackCourse(after day: DayProjection) -> CourseItem?' in swift and 'nextDay(after: day)?.courses.first' in swift, "widget fallback selects only the next-day first course")
require('current == nil && next == nil ? snapshot.fallbackCourse(after: selectedDay) : nil' in swift, "widget only applies the next-day fallback when today has no current or next course")
require('return "明天第一节"' in swift and 'return "明天无课"' in swift, "widget labels fallback and rest states explicitly")
require('return "明天无课 · 好好休息"' in swift, "widget uses the explicit tomorrow rest summary")
require('let featured = current ?? next ?? fallback' in swift, "widget presents current, next, or fallback course in priority order")
require('keys: ["timeText", "time", "periodText"]' in swift, "widget parser accepts the course time string")
require("case .noData" in swift and "case .corrupt" in swift and "isStale" in swift, "widget handles no-data, corrupt, and stale states")
require("nextMidnight" in swift and "coursePoints" in swift and "$0.start, $0.end" in swift, "timeline includes midnight and every parsed course boundary")
require('coursePoints.filter { $0 > now && $0 < nextMidnight }' in swift, "timeline bounds course transitions before midnight without suppressing close boundaries")
require('if let expiresAt = snapshot.expiresAt, expiresAt > now' in swift and 'candidates.append(expiresAt)' in swift, "timeline includes the snapshot expiry boundary")
require('schemaVersion == nil || schemaVersion == 1' in swift, "widget rejects unsupported snapshot schema versions")
require("已请求刷新桌面小组件，系统可能需要几秒生效。" in settings_page, "settings success message describes best-effort WidgetKit refresh")
require("小组件同步失败，请检查安装包签名或稍后重试。" in settings_page, "settings failure message remains available")

require("flutter test --concurrency=1" in workflow, "release workflow runs Flutter tests sequentially")
require("Test Android widget parser" in workflow and ":app:testDebugUnitTest" in workflow, "release workflow runs Android native widget tests")
require("Upload Flutter test log" in workflow and 'flutter-test.log' in workflow, "release workflow preserves a diagnostic Flutter test log")
require("Verify iOS native integrations" in workflow and "python3 scripts/verify_ios_widget_project.py" in workflow, "release workflow runs static iOS widget verification before build")
require('WIDGET_APPEX="$RUNNER_APP/PlugIns/SchedulrWidget.appex"' in workflow and 'INTENT_APPEX="$RUNNER_APP/PlugIns/SchedulrIntentExtension.appex"' in workflow, "release workflow locates both embedded extensions")
require("CFBundleShortVersionString" in workflow and "CFBundleVersion" in workflow, "release workflow reads both app and widget version fields")
require("flutter build ios --release --config-only --no-codesign" in workflow, "release workflow generates Flutter iOS configuration without signing")
require('CODE_SIGN_IDENTITY=""' in workflow and 'DEVELOPMENT_TEAM=""' in workflow and 'PROVISIONING_PROFILE_SPECIFIER=""' in workflow, "release workflow clears Xcode signing identity, team, and profile")
require('PACKAGE_ROOT="$PWD/build/ios/iphoneos"' in workflow and 'FLUTTER_BUILD_DIR="$PWD/build"' in workflow, "release workflow uses Flutter's standard iOS output directory")
require('test -s "$RUNNER_APP/Frameworks/Flutter.framework/Flutter"' in workflow and 'flutter_assets' in workflow, "release workflow verifies Flutter frameworks and assets")
require('UNCOMPRESSED_KB' in workflow and 'test "$UNCOMPRESSED_KB" -gt 10000' in workflow, "release workflow rejects undersized iOS app bundles")
require("Package unsigned IPA" in workflow and "ditto -c -k" in workflow, "release workflow packages the complete app with ditto")
require("Payload/Runner.app/Runner" in workflow and "Payload/Runner.app/Frameworks/Flutter.framework/Flutter" in workflow, "release workflow verifies executable and Flutter framework inside IPA")
require('IPA_BYTES' in workflow and 'test "$IPA_BYTES" -gt 5000000' in workflow, "release workflow rejects undersized IPA artifacts")
require("EXPECTED_SHORT_VERSION=\"${APP_VERSION%%+*}\"" in workflow and 'EXPECTED_BUILD_VERSION="$GITHUB_RUN_NUMBER"' in workflow, "release workflow derives authoritative versions from pubspec and the Actions run")
require('set_or_add_plist_string "$RUNNER_APP/Info.plist" CFBundleShortVersionString "$EXPECTED_SHORT_VERSION"' in workflow, "release workflow creates the Runner short-version key when missing")
require('set_or_add_plist_string "$RUNNER_APP/Info.plist" CFBundleVersion "$EXPECTED_BUILD_VERSION"' in workflow, "release workflow creates the Runner build-version key when missing")
require('set_or_add_plist_string "$WIDGET_APPEX/Info.plist" CFBundleShortVersionString "$EXPECTED_SHORT_VERSION"' in workflow, "release workflow creates the Widget short-version key when missing")
require('set_or_add_plist_string "$WIDGET_APPEX/Info.plist" CFBundleVersion "$EXPECTED_BUILD_VERSION"' in workflow, "release workflow creates the Widget build-version key when missing")
require('set_or_add_plist_string "$INTENT_APPEX/Info.plist" CFBundleShortVersionString "$EXPECTED_SHORT_VERSION"' in workflow, "release workflow creates the Intent short-version key when missing")
require('[[ "$RUNNER_BUILD_VERSION" == "$WIDGET_BUILD_VERSION" ]]' in workflow, "release workflow compares Runner and widget build versions")
require('[[ "$RUNNER_SHORT_VERSION" == "$INTENT_SHORT_VERSION" ]]' in workflow, "release workflow compares Runner and Intent short versions")
require('[[ "$RUNNER_BUILD_VERSION" == "$INTENT_BUILD_VERSION" ]]' in workflow, "release workflow compares Runner and Intent build versions")

require('verify_signed_ios_widget_ipa.py' in SIGNED_IPA_VERIFIER.name and 'codesign' in SIGNED_IPA_VERIFIER.read_text(), "signed IPA verifier checks codesign entitlements")

if errors:
    print(f"iOS widget project verification FAILED: {len(errors)} issue(s)")
    for error in errors:
        print(f"  FAIL: {error}")
    print(f"  Passed checks before failure: {len(checks)}")
    raise SystemExit(1)

print(f"iOS widget project verification PASSED: {len(checks)} checks")
for check in checks:
    print(f"  OK: {check}")
