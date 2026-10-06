# Provider and licensing ledger

Verification snapshot: 2026-10-05

This ledger is a release gate, not a claim that every optional provider is
already production-enabled.

## Open-Meteo

Use: weather + geocoding.

Verified:
- free/open-access API is non-commercial;
- applications with subscriptions or advertising are considered commercial;
- commercial plans use dedicated customer endpoints and provider credentials;
- data attribution is required under CC BY 4.0.

Sources:
- https://open-meteo.com/en/terms
- https://open-meteo.com/en/pricing
- https://open-meteo.com/en/docs/geocoding-api

CamperBoss policy:
- non-commercial builds may use the public endpoints;
- commercial builds must configure approved customer endpoints;
- attribution must be present in product/legal surfaces before commercial
  release.

## openrouteservice / HeiGIT

Use: optional road routing with HGV restrictions.

Verified:
- api.openrouteservice.org is deprecated in favor of
  api.heigit.org/openrouteservice/...;
- public service enforces endpoint/query limits.

Sources:
- https://ask.openrouteservice.org/t/deprecating-api-openrouteservice-org-in-favour-of-api-heigit-org/7912
- https://openrouteservice.org/restrictions/

CamperBoss policy:
- production client does not embed a provider API key;
- production routing uses an approved server-side proxy or self-hosted service;
- direct provider access is development-only.

## OpenFreeMap / OpenStreetMap / OpenMapTiles

Use: online MapLibre base map.

Verified:
- OpenFreeMap public instance permits commercial map display and requires
  attribution;
- OpenFreeMap Terms prohibit automated data collection without permission;
- OpenFreeMap provides self-hosting/full-download options.

Sources:
- https://openfreemap.org/
- https://openfreemap.org/tos/
- https://openfreemap.org/quick_start/

CamperBoss policy:
- public OpenFreeMap may be used for ordinary online rendering;
- MapLibre offline-region bulk collection is disabled against the public
  OpenFreeMap endpoint;
- offline download requires a separately approved/self-hosted style endpoint.

Required attribution:
OpenFreeMap © OpenMapTiles · Data © OpenStreetMap contributors.

## Google ML Kit

Use: Android document scanner and text recognition.

Verified:
- ML Kit APIs are documented as on-device;
- Document Scanner uses the Google Play Services installation path.

Sources:
- https://developers.google.com/ml-kit/guides
- https://developers.google.com/ml-kit/tips/installation-paths

CamperBoss policy:
- no document/OCR payload is uploaded by CamperBoss;
- native scan/OCR capability is Android-only in the active release scope.

## POI/offline content provider

Status: NOT SELECTED / NOT PRODUCTION ENABLED.

Every production POI/offline package must declare source, licence, attribution
and package metadata. The app rejects package catalog entries that omit those
fields. Provider selection remains separate from demo data: no fake production
catalog is shown.
