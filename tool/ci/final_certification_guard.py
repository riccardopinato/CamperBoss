#!/usr/bin/env python3
"""Static preflight for the final STEP 16 Android/Web release candidate."""
from __future__ import annotations

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "build" / "evidence"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read(path: str) -> str:
    file = ROOT / path
    if not file.is_file():
        fail(f"missing final-certification input: {path}")
    return file.read_text(encoding="utf-8")


def main() -> None:
    findings: list[str] = []

    workflow = read(".github/workflows/release-core-platforms.yml")
    router = read("lib/core/router/app_router.dart")
    main_dart = read("lib/main.dart")
    manifest = read("android/app/src/main/AndroidManifest.xml")
    readme = read("README.md")
    certification = json.loads(read("release/step16_certification.json"))

    if re.search(r"^\s{2}ios:\s*$", workflow, re.MULTILINE):
        findings.append("iOS release job is active although iOS is deferred")
    for job in ["Android QA release APK", "Web release"]:
        if job not in workflow:
            findings.append(f"active platform build missing: {job}")

    for path in [
        "docs/security/step-16o-threat-model.md",
        "docs/security/provider-licensing-ledger.md",
        "docs/privacy/data-inventory.md",
        "docs/performance/step-16p-baseline.md",
        "docs/release/step-16q-certification.md",
        "test/provider_trust_test.dart",
        "test/performance_baseline_test.dart",
        ".maestro/applab-release-core-final.yaml",
        ".maestro/applab-performance.json",
    ]:
        if not (ROOT / path).is_file():
            findings.append(f"required evidence/harness missing: {path}")

    for locale in ["en", "it", "de", "fr", "es", "pt"]:
        if not (ROOT / "assets" / "translations" / f"{locale}.json").is_file():
            findings.append(f"translation catalog missing: {locale}")

    for route in ["/", "/map", "/trips", "/camper", "/more"]:
        if f"'{route}'" not in router:
            findings.append(f"top-level route missing: {route}")

    if "usePathUrlStrategy" in main_dart or "setUrlStrategy(PathUrlStrategy" in main_dart:
        findings.append("GitHub Pages preview must keep hash routing unless a rewrite host is configured")
    if "#/map" not in readme:
        findings.append("README does not disclose hash-route Web preview semantics")

    if 'android:allowBackup="false"' not in manifest:
        findings.append("Android backup protection regressed")
    if 'android:usesCleartextTraffic="false"' not in manifest:
        findings.append("Android cleartext protection regressed")

    if certification.get("activePlatforms") != ["android", "web"]:
        findings.append("certification platform scope drift")
    if certification.get("ios", {}).get("blocksRelease") is not False:
        findings.append("iOS unexpectedly blocks current release")
    if certification.get("ios", {}).get("iapInScope") is not False:
        findings.append("iOS IAP unexpectedly returned to scope")
    if certification.get("finalVerdict") != "BLOCKED":
        findings.append("final verdict must remain BLOCKED until runtime/store evidence exists")

    EVIDENCE.mkdir(parents=True, exist_ok=True)
    report = {
        "staticPreflight": "PASS" if not findings else "FAIL",
        "finalVerdict": certification.get("finalVerdict"),
        "activePlatforms": certification.get("activePlatforms"),
        "externalBlockedBy": certification.get("blockedBy", []),
        "findings": findings,
    }
    (EVIDENCE / "step16-final-static-preflight.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    if findings:
        fail("; ".join(findings))
    print("STEP 16 static preflight: PASS; final runtime verdict remains BLOCKED")


if __name__ == "__main__":
    main()
