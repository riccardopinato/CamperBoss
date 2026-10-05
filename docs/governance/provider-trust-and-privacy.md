# STEP 16O — Provider Trust, Privacy & Licensing

Status: SOFTWARE GATE IMPLEMENTED — external commercial-provider approval remains a release configuration decision.

## Trust model

CamperBoss is local-first. Core user data stays in app-private storage unless the
user explicitly exports a backup or invokes an online provider feature.

### Data classes

| Data class | Local storage | Network exposure | Notes |
|---|---|---|---|
| Vehicle profile | app database/local storage | routing only when user requests a route | dimensions/mass may be sent to routing provider as restrictions |
| Trips/stages | app database/local storage | geocoding/routing on explicit action | waypoint names/coordinates can leave device |
| GPS/current location | runtime memory/local selected state | weather/geocoding/map provider when invoked | never uploaded to a CamperBoss account |
| Vehicle documents/photos/PDF | app-private files | none by default | Android backup disabled; export only by explicit user action |
| OCR text | local app state | none by CamperBoss | Google ML Kit processing is on-device for the used text-recognition path; model delivery may use Google Play Services |
| Maintenance/finance/checklists/journal | local database/local storage | none by default | included only in explicit local backup/export |
| GPX/memories/photos | app-private storage | map/routing only when user explicitly requests related online operations | no automatic cloud sync |
| Web data | browser localStorage | provider requests only when invoked | browser storage is not encrypted at rest by CamperBoss |

## Provider boundaries

### Routing

Production builds must use `CAMPERBOSS_ROUTING_PROXY_URL`, an HTTPS endpoint
owned/approved for the product. The Flutter client never treats an embedded ORS
API key as a production secret.

Direct OpenRouteService access exists only when all are true:
- build is not release mode;
- `CAMPERBOSS_ALLOW_DIRECT_ORS_DEV=true`;
- `ORS_API_KEY` is supplied at build time.

The production proxy must keep provider credentials server-side, rate-limit
requests, reject arbitrary upstream URLs, avoid logging full route bodies, and
return the ORS-compatible response contract used by the client.

### Weather and geocoding

Open-Meteo's free API is non-commercial. CamperBoss therefore allows its public
endpoint only when `CAMPERBOSS_COMMERCIAL_DISTRIBUTION=false`.

Before ads, subscriptions or IAP are enabled, production must set approved HTTPS
endpoints with:
- `CAMPERBOSS_WEATHER_ENDPOINT`
- `CAMPERBOSS_GEOCODING_ENDPOINT`

Those may point to a paid Open-Meteo customer endpoint or an approved proxy.

### Maps

The online MapLibre style remains an online browsing source. Offline bulk map
downloads are a separate trust boundary and are disabled unless an explicitly
approved HTTPS style is supplied via `CAMPERBOSS_OFFLINE_MAP_STYLE_URL`.

Known public/shared tile hosts are rejected for bulk offline download. This
prevents the app from silently prefetching from infrastructure whose usage policy
was not approved for that purpose.

### Offline POI/content packages

Remote manifests and package URLs must be HTTPS. Package downloads are host
allow-listed and SHA-256/size verified before activation. POI packages must
include source, license, attribution and region metadata.

## Current provider/legal review — 2026-10-05

- Open-Meteo free API: non-commercial only; apps with ads/subscriptions are
  commercial. Paid plans provide commercial-use licensing and dedicated
  customer endpoints. Weather data requires attribution under CC BY 4.0.
  Source: https://open-meteo.com/en/terms and https://open-meteo.com/en/pricing
- OpenRouteService: API is quota/restriction governed. Client-side API keys are
  not treated as secrets by CamperBoss; production requires a proxy/provider
  boundary. Source: https://openrouteservice.org/restrictions/
- OpenStreetMap data: attribution to OpenStreetMap contributors and ODbL notice
  are required. Public OSM tile servers are not a general free tile API and are
  not approved for CamperBoss offline bulk download.
  Source: https://www.openstreetmap.org/copyright
- OpenFreeMap: current online map integration is treated as an online service
  under its published Terms. Because its Terms do not constitute an explicit
  CamperBoss offline-bulk approval, CamperBoss does not use that public endpoint
  for offline region bulk downloads by default.
  Source: https://openfreemap.org/tos/
- Google ML Kit: the text-recognition API used by CamperBoss performs recognition
  on-device; unbundled model delivery can use Google Play Services. No document
  image or OCR text is intentionally uploaded by CamperBoss.
  Source: https://developers.google.com/ml-kit/guides and
  https://developers.google.com/ml-kit/vision/text-recognition/v2/android

## At-rest decision

Android/mobile private files and SQLite are protected primarily by the OS app
sandbox. Whole-database application-level encryption is not introduced in this
release because it would add key lifecycle, migration and recovery risk without
a remote multi-user threat model. The explicit controls are:

- Android OS backup disabled;
- cleartext network disabled;
- sensitive documents copied to app-private storage;
- no mandatory account/cloud sync;
- backup/export is user-initiated;
- no secrets persisted as application data.

If future cloud sync/account support is added, encryption/key-management must be
re-evaluated before that feature enters release scope.

## Account/cloud boundary

Google Sign-In and cloud backup remain optional future capabilities. They are not
required for core use and are not part of STEP 16. No account is created
implicitly.

## Release gate

The release candidate must pass `python3 tool/ci/trust_guard.py`. Commercial
distribution additionally requires explicit production provider configuration;
the guard intentionally rejects claims that free public endpoints are a
commercial production architecture.
