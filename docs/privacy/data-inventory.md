# CamperBoss data inventory and disclosure matrix

Snapshot: 2026-10-05

| Data | Purpose | Stored locally | Sent off device | Destination / condition |
| --- | --- | --- | --- | --- |
| Vehicle profile | camper-aware planning | yes | dimensions may be sent for routing | approved routing proxy/provider only when user calculates route |
| Trips/stages | trip planning | yes | geocoded stage text; route coordinates | Open-Meteo geocoding or configured commercial endpoint; routing proxy |
| Current/selected location | map/weather | selected state | yes when live weather/geocoding is requested | configured weather/geocoding provider |
| Journal/checklists | local organization | yes | no by default | none |
| Expenses/fuel/bookings | finance | yes | no by default | none |
| Vehicle documents/PDF/images | private archive | yes, app-private | no by CamperBoss | ML Kit processing remains on-device |
| OCR text | document metadata assistance | yes only after user save/confirmation | no by CamperBoss | on-device ML Kit |
| Maintenance attachments | private archive | yes | no by default | none |
| GPX tracks/memories/photos | travel history | yes | no by default | none |
| Search index | local search | yes | no | none |
| Offline package metadata/files | offline operation | yes | download request only | explicitly allowed HTTPS package hosts |
| Online map requests | map rendering | cache/runtime | yes | current online map provider/CDN |
| Offline map requests | offline map | yes | only when configured | approved/self-hosted offline map provider |
| Notification schedule | reminders | yes/native OS | no remote push in current core | Android notification framework |
| Backup/export | user-controlled portability | user-selected file | no automatic cloud upload | destination chosen by user |

## Account/cloud status

No mandatory account exists in the current release. Google Sign-In and optional
cloud backup remain future decisions. They must not become prerequisites for
the local-first core.

## Monetization status

No active billing SDK, subscription checkout or advertising SDK is included in
the current Release Core. Before enabling commercial distribution, provider
configuration must use commercial-capable weather/geocoding infrastructure.

## Deletion

Entity deletion and backup restore use the managed-media/reference-safe
lifecycle introduced in STEP 16I/16K. Deleting one entity must not remove a
file still referenced by another entity.
