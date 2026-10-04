#!/usr/bin/env python3
"""Deterministic release/supply-chain checks for CamperBoss.

Standard-library only: CI must not need an extra scanner dependency before it
can verify its own release inputs.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "build" / "evidence"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def write_report(name: str, payload: dict) -> None:
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    path = EVIDENCE / name
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote {path.relative_to(ROOT)}")


def read_pubspec_version() -> tuple[str, int]:
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$", text, re.MULTILINE)
    if not match:
        fail("pubspec.yaml must contain semantic version + numeric build code")
    return match.group(1), int(match.group(2))


def identity() -> None:
    ledger_path = ROOT / "release" / "release_identity.json"
    if not ledger_path.is_file():
        fail("release/release_identity.json is required")
    ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    version_name, version_code = read_pubspec_version()
    previous = int(ledger["previousVersionCode"])

    errors: list[str] = []
    if ledger["versionName"] != version_name:
        errors.append("versionName does not match pubspec.yaml")
    if int(ledger["versionCode"]) != version_code:
        errors.append("versionCode does not match pubspec.yaml")
    if version_code <= previous:
        errors.append("versionCode must be strictly greater than previousVersionCode")
    if ledger["packageName"] != "com.camperboss.camperboss":
        errors.append("unexpected Android packageName")
    if version_name == "0.1.0" and version_code == 1:
        errors.append("template release identity 0.1.0+1 is forbidden")

    gradle = (ROOT / "android" / "app" / "build.gradle.kts").read_text(encoding="utf-8")
    if 'applicationId = "com.camperboss.camperboss"' not in gradle:
        errors.append("Android applicationId drift")
    if "requireReleaseSigning" not in gradle:
        errors.append("Play release signing hard-fail contract is missing")

    if errors:
        fail("; ".join(errors))

    write_report(
        "release-identity.json",
        {
            "sourceSha": os.getenv("GITHUB_SHA", "local"),
            "versionName": version_name,
            "versionCode": version_code,
            "previousVersionCode": previous,
            "packageName": ledger["packageName"],
            "channel": ledger["channel"],
            "status": "PASS",
        },
    )


def _package_root(uri: str, config_dir: Path) -> Path | None:
    parsed = urlparse(uri)
    if parsed.scheme == "file":
        return Path(unquote(parsed.path)).resolve()
    if parsed.scheme:
        return None
    return (config_dir / unquote(uri)).resolve()


def supply_chain() -> None:
    package_config_path = ROOT / ".dart_tool" / "package_config.json"
    if not package_config_path.is_file():
        fail("run flutter pub get before supply-chain audit")

    try:
        deps = json.loads(
            subprocess.check_output(
                ["flutter", "pub", "deps", "--json"],
                cwd=ROOT,
                text=True,
            )
        )
    except (subprocess.CalledProcessError, json.JSONDecodeError) as error:
        fail(f"unable to read Flutter dependency graph: {error}")

    packages = deps.get("packages", [])
    kinds = {p.get("name"): p.get("kind") for p in packages}
    sources = {p.get("name"): p.get("source") for p in packages}
    disallowed_sources = sorted(
        name
        for name, source in sources.items()
        if name != "camperboss" and source not in {"hosted", "sdk"}
    )

    config = json.loads(package_config_path.read_text(encoding="utf-8"))
    config_dir = package_config_path.parent
    missing_direct_licenses: list[str] = []
    missing_transitive_licenses: list[str] = []
    audited: list[dict] = []

    for package in config.get("packages", []):
        name = package.get("name", "")
        if name == "camperboss" or sources.get(name) == "sdk":
            continue
        root = _package_root(package.get("rootUri", ""), config_dir)
        if root is None or not root.exists():
            missing = missing_direct_licenses if kinds.get(name) == "direct" else missing_transitive_licenses
            missing.append(name)
            continue
        license_files = sorted(
            p.name
            for p in root.iterdir()
            if p.is_file() and p.name.lower().startswith(("license", "copying", "notice"))
        )
        if not license_files:
            missing = missing_direct_licenses if kinds.get(name) == "direct" else missing_transitive_licenses
            missing.append(name)
        audited.append(
            {
                "name": name,
                "kind": kinds.get(name),
                "source": sources.get(name),
                "licenseFiles": license_files,
            }
        )

    unpinned_actions: list[str] = []
    action_pattern = re.compile(r"uses:\s*[^@\s]+@([^\s#]+)")
    for workflow in sorted((ROOT / ".github" / "workflows").glob("*.yml")):
        for match in action_pattern.finditer(workflow.read_text(encoding="utf-8")):
            ref = match.group(1)
            if not re.fullmatch(r"[0-9a-f]{40}", ref):
                unpinned_actions.append(f"{workflow.name}:{ref}")

    gem_lock = (ROOT / "Gemfile.lock").read_text(encoding="utf-8") if (ROOT / "Gemfile.lock").is_file() else ""
    ruby_lock_ok = "fastlane (2.240.1)" in gem_lock and "  4.0.22" in gem_lock

    report = {
        "sourceSha": os.getenv("GITHUB_SHA", "local"),
        "packageCount": len(audited),
        "packages": audited,
        "disallowedSources": disallowed_sources,
        "missingDirectLicenses": sorted(missing_direct_licenses),
        "missingTransitiveLicenses": sorted(missing_transitive_licenses),
        "unpinnedActions": unpinned_actions,
        "rubyLockPinned": ruby_lock_ok,
    }
    write_report("supply-chain.json", report)

    if disallowed_sources:
        fail("non-hosted/non-SDK Flutter dependencies: " + ", ".join(disallowed_sources))
    if missing_direct_licenses:
        fail("direct dependencies missing license evidence: " + ", ".join(sorted(missing_direct_licenses)))
    if unpinned_actions:
        fail("GitHub Actions must be pinned to full commit SHA: " + ", ".join(unpinned_actions))
    if not ruby_lock_ok:
        fail("Gemfile.lock must pin Fastlane 2.240.1 and Bundler 4.0.22")


SECRET_PATTERNS = {
    "pem_private_key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "google_api_key": re.compile(r"AIza[0-9A-Za-z_-]{35}"),
    "github_pat": re.compile(r"(?:github_pat_[A-Za-z0-9_]{30,}|ghp_[A-Za-z0-9]{30,})"),
    "aws_access_key": re.compile(r"AKIA[0-9A-Z]{16}"),
    "openai_key": re.compile(r"sk-[A-Za-z0-9_-]{32,}"),
}


def tracked_files() -> list[Path]:
    output = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    return [ROOT / p.decode("utf-8") for p in output.split(b"\0") if p]


def secret_scan() -> None:
    findings: list[dict] = []
    forbidden_names = {
        "android/key.properties",
    }
    forbidden_suffixes = {".jks", ".keystore", ".p12", ".pfx"}

    for path in tracked_files():
        rel = path.relative_to(ROOT).as_posix()
        if rel in forbidden_names or path.suffix.lower() in forbidden_suffixes:
            findings.append({"file": rel, "type": "tracked_secret_material"})
            continue
        if rel == "tool/ci/release_guard.py":
            # The scanner contains its own high-confidence pattern literals.
            continue
        if not path.is_file() or path.stat().st_size > 2_000_000:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if '"type": "service_account"' in text and '"private_key"' in text:
            findings.append({"file": rel, "type": "service_account_json"})
        for name, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                findings.append({"file": rel, "type": name})

    write_report("secret-scan.json", {"findings": findings, "status": "PASS" if not findings else "FAIL"})
    if findings:
        fail("high-confidence secret material detected in tracked files")


SAST_PATTERNS = {
    "android_cleartext_enabled": re.compile(r'android:usesCleartextTraffic\s*=\s*"true"'),
    "android_backup_enabled": re.compile(r'android:allowBackup\s*=\s*"true"'),
    "dart_global_http_override": re.compile(r"HttpOverrides\.global\s*="),
    "dart_accept_all_certificates": re.compile(r"badCertificateCallback[\s\S]{0,160}(?:=>\s*true|return\s+true)"),
}


def sast() -> None:
    findings: list[dict] = []
    roots = [ROOT / "lib", ROOT / "android", ROOT / "ios", ROOT / "web"]
    suffixes = {".dart", ".kt", ".kts", ".java", ".xml", ".swift", ".m", ".mm", ".html", ".js"}
    for base in roots:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in suffixes:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            for rule, pattern in SAST_PATTERNS.items():
                if pattern.search(text):
                    findings.append({"file": path.relative_to(ROOT).as_posix(), "rule": rule})

    write_report("sast.json", {"findings": findings, "status": "PASS" if not findings else "FAIL"})
    if findings:
        fail("blocking SAST findings detected")


def coverage(lcov: Path, minimum: float) -> None:
    if not lcov.is_file():
        fail(f"coverage file missing: {lcov}")
    found = hit = 0
    for line in lcov.read_text(encoding="utf-8").splitlines():
        if line.startswith("LF:"):
            found += int(line[3:])
        elif line.startswith("LH:"):
            hit += int(line[3:])
    if found <= 0:
        fail("LCOV contains no executable lines")
    percent = hit * 100.0 / found
    report = {
        "lineFound": found,
        "lineHit": hit,
        "lineCoveragePercent": round(percent, 2),
        "minimumPercent": minimum,
        "status": "PASS" if percent >= minimum else "FAIL",
    }
    write_report("coverage.json", report)
    print(f"Line coverage: {percent:.2f}% (minimum {minimum:.2f}%)")
    if percent < minimum:
        fail("coverage threshold not met")


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("identity")
    sub.add_parser("supply-chain")
    sub.add_parser("secrets")
    sub.add_parser("sast")
    cov = sub.add_parser("coverage")
    cov.add_argument("--lcov", default="coverage/lcov.info")
    cov.add_argument("--minimum", type=float, default=20.0)
    args = parser.parse_args()

    os.chdir(ROOT)
    if args.command == "identity":
        identity()
    elif args.command == "supply-chain":
        supply_chain()
    elif args.command == "secrets":
        secret_scan()
    elif args.command == "sast":
        sast()
    elif args.command == "coverage":
        coverage(ROOT / args.lcov, args.minimum)


if __name__ == "__main__":
    main()
