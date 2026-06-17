# STEP 12 — GPX, ricordi e statistiche di viaggio

## Obiettivo

Creare uno storico geografico senza introdurre subito tracking continuo in background.

Funzioni:

- import GPX;
- esportazione GPX;
- associazione a viaggio;
- traccia sulla mappa;
- foto e ricordi geolocalizzati;
- luoghi visitati;
- statistiche.

## Scope

Leggere soltanto:

- viaggi;
- mappa;
- journal;
- foto;
- POI;
- clustering;
- import/export;
- database Drift.

Non implementare tracking GPS continuo o condivisione live.

## GPX

Supportare almeno:

- `trk`;
- `trkseg`;
- `trkpt`;
- `rte`;
- `rtept`;
- `wpt`.

Modelli:

```dart
class GeoPoint {
  final double latitude;
  final double longitude;
  final double? elevation;
  final DateTime? recordedAt;
}

class GpxTrack {
  final String id;
  final String? tripId;
  final String name;
  final List<GeoPoint> points;
  final double distanceMeters;
  final Duration? duration;
}
```

Validare:

* coordinate;
* dimensione file;
* XML;
* numero massimo di punti;
* timestamp;
* file corrotto.

Per file grandi:

* parsing in isolate;
* semplificazione geometria;
* conservazione opzionale della traccia originale;
* nessun blocco UI.

## Calcoli

Calcolare:

* distanza;
* durata;
* dislivello se disponibile;
* velocità media;
* giorni;
* Paesi e città se dati disponibili;
* numero luoghi;
* costi collegati;
* consumo collegato al viaggio.

Non inventare statistiche in assenza di dati.

## Ricordi

```dart
class TravelMemory {
  final String id;
  final String? tripId;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime occurredAt;
  final List<String> localPhotoPaths;
  final String? poiId;
  final Set<String> tags;
}
```

Supportare:

* creazione manuale;
* foto;
* posizione;
* data;
* tag;
* collegamento viaggio;
* collegamento POI;
* preferito.

## EXIF

Quando l'utente importa una foto:

* leggere coordinate EXIF se presenti;
* leggere data originale;
* mostrare anteprima;
* chiedere conferma;
* non usare automaticamente coordinate senza consenso.

Non scansionare tutta la galleria senza azione esplicita.

## Mappa ricordi

Mostrare:

* marker ricordi;
* cluster;
* foto anteprima;
* filtro per viaggio;
* filtro data;
* filtro tag;
* luoghi visitati e pianificati distinti.

Riutilizzare clustering e tema esistenti.

## Timeline

Creare viste:

* timeline;
* mappa;
* elenco;
* riepilogo viaggio.

## Esportazione

Supportare:

* GPX;
* GeoJSON opzionale;
* ZIP delle foto selezionate;
* collegamento con BackupService.

## Privacy

* foto locali;
* nessun caricamento automatico;
* coordinate private;
* condivisione soltanto tramite azione esplicita;
* rimozione metadati sensibili dalle copie condivise quando configurato.

## Test

* parser GPX;
* GPX corrotto;
* coordinate invalide;
* distanza;
* semplificazione;
* export/import roundtrip;
* EXIF;
* conferma coordinate;
* clustering;
* statistiche;
* eliminazione foto;
* provider;
* widget timeline e mappa.

## Criteri di completamento

* GPX importabile e visibile;
* GPX esportabile;
* ricordi persistenti;
* foto e coordinate confermate;
* statistiche derivate da dati reali;
* nessun tracking continuo non richiesto.

## Commit

`feat(history): add GPX travel memories and statistics`
