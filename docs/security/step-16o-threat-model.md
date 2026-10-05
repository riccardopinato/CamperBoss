# STEP 16O — Threat model and trust boundaries

Snapshot: 2026-10-05
Active release scope: Android + Web. iOS is deferred.

## Security objectives

CamperBoss is local-first. The core must remain usable without an account or
cloud service. Sensitive local content must not be silently uploaded, backed up
by the OS, logged, or exposed to an untrusted provider.

## Assets

| Asset | Sensitivity | Storage/owner | Primary risks | Control |
| --- | --- | --- | --- | --- |
| Vehicle profile | personal | app DB/localStorage | unintended disclosure, stale restore | app sandbox, versioned backup |
| Trips / journal / finance | personal | app DB/localStorage | loss, disclosure, corrupt restore | local-first, backup hash/rollback |
| Vehicle documents | high | private app files + metadata | cloud backup, orphan files, path traversal | Android backup disabled, managed media lifecycle |
| GPX / memories / photos | high | private app files + metadata | location disclosure, orphan/shared file deletion | reference-safe lifecycle |
| Current/search location | personal | transient + selected local state | provider disclosure | HTTPS, provider inventory, no logging |
| Route waypoints + vehicle dimensions | personal-ish | remote routing request | provider disclosure, API-key abuse | production proxy boundary |
| Offline packages | untrusted input | app support files | tampering, oversized payload, malicious metadata | HTTPS allowlist, hash/size verification |
| Release credentials | secret | CI secrets only | repository/log leakage | secret scan, no client embedding |

## Trust boundaries

### Local sandbox

SQLite, SharedPreferences/localStorage and app-private files are trusted only
against other ordinary apps/processes. They are not described as cryptographic
at-rest encryption. Android OS backup is disabled for the current release.

Additional application-level encryption is not added in STEP 16O because the
current product does not hold server credentials, payment data or health data.
If account/cloud sync is introduced, the threat model must be reopened before
shipping it.

### Routing

Production must not embed an OpenRouteService API key in the Flutter binary.
Release builds accept routing only through CAMPERBOSS_ROUTING_PROXY_URL. The
proxy must expose the ORS-compatible /v2/directions path, keep provider
credentials server-side, rate-limit abuse, redact request logs and return only
the response needed by the app.

Direct ORS access is development-only and requires the explicit
CAMPERBOSS_ALLOW_DIRECT_ORS_DEV flag. The development endpoint uses the current
HeiGIT route rather than the deprecated api.openrouteservice.org host.

### Weather and geocoding

The public Open-Meteo endpoint is permitted only while the distribution is
explicitly non-commercial. A commercial build must supply approved customer
endpoints through CAMPERBOSS_WEATHER_ENDPOINT and
CAMPERBOSS_GEOCODING_ENDPOINT.

The app sends coordinates for weather and a user-entered search string for
geocoding. Responses are size-capped and endpoints must be HTTPS.

### Online and offline maps

Online rendering may use the public OpenFreeMap MapLibre style with required
attribution. Offline region collection is a different trust boundary:
CamperBoss will not bulk-download the public OpenFreeMap tile service.

Offline region download is enabled only when
CAMPERBOSS_OFFLINE_MAP_STYLE_URL points to an explicitly approved HTTPS source
that is not a known public bulk-forbidden tile host. Intended production
options are a self-hosted/OpenFreeMap-derived endpoint or another provider whose
terms explicitly permit the required offline caching.

### Offline manifests/packages

Remote manifests and packages require HTTPS. Package host allowlists, expected
size and SHA-256 verification are enforced before activation. Failed
activation restores the previous candidate where applicable.

### ML Kit

Document scanning/text recognition are Android-only in the active release
scope. ML Kit processing is treated as on-device processing. No document OCR
text is uploaded by CamperBoss itself.

## Logging policy

Release code must not log:
- API keys, service-account JSON or signing material;
- document contents/OCR text;
- exact route payloads or full location history;
- backup payloads.

Provider and network errors exposed to users should contain status/category,
not credentials or raw sensitive payloads.

## Re-open conditions

Repeat this threat model before enabling any of:
- Google Sign-In or cloud backup/sync;
- ads, subscriptions or IAP;
- a new POI/map/routing provider;
- remote AI;
- analytics/crash reporting that receives user content;
- iOS release work.
