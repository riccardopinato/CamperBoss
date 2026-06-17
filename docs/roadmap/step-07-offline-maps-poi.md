# STEP 7 — Mappe e POI offline

## Obiettivo

Rendere realmente disponibili offline:

- cartografia regionale;
- POI camper;
- filtri;
- dettagli POI;
- aggiornamenti regionali.

Lo step deve riutilizzare Offline Content Core e Download Manager.

## Scope

Leggere soltanto:

- feature mappa;
- servizi e repository POI;
- filtri mappa;
- controller della mappa;
- Offline Content Core;
- Download Manager;
- database Drift relativo ai POI.

Non modificare planner, documenti, manutenzione o budget.

## Decisione tecnica

Verificare prima il motore cartografico esistente.

Se è `flutter_map`:

- conservarlo;
- utilizzare una soluzione PMTiles compatibile con la versione installata;
- non migrare a MapLibre senza autorizzazione.

Se il motore non supporta in modo affidabile PMTiles locali:

- creare prima un proof of concept isolato;
- non sostituire tutta la mappa nello stesso task;
- fermarsi se è necessaria una migrazione completa.

## Regola mappe

Non estrarre regioni PMTiles sul telefono.

Usare file regionali già generati:

```text
italy_north_2026-06.pmtiles
italy_centre_2026-06.pmtiles
italy_south_2026-06.pmtiles
alps_2026-06.pmtiles
```

Il telefono deve soltanto:

1. leggere il manifest;
2. scaricare;
3. verificare;
4. registrare;
5. caricare;
6. aggiornare;
7. eliminare.

## Contratti suggeriti

```dart
abstract interface class OfflineMapRepository {
  Stream<List<InstalledMapRegion>> watchInstalledRegions();
  Future<void> activateRegion(String packageId);
  Future<void> deactivateRegion(String packageId);
  Future<void> deleteRegion(String packageId);
  Future<MapSourceConfiguration?> resolveActiveSource();
}

abstract interface class PoiRepository {
  Stream<List<Poi>> watchInBounds(
    GeoBounds bounds,
    Set<PoiCategory> categories,
  );

  Future<void> importPackage(
    String packageId,
    String localPath,
  );

  Future<void> removePackage(String packageId);
}
```

## POI

Categorie minime:

```dart
enum PoiCategory {
  camperArea,
  campsite,
  parking,
  water,
  wasteDisposal,
  lpg,
  workshop,
  servicePoint,
  viewpoint,
}
```

Campi minimi:

```dart
class Poi {
  final String id;
  final String packageId;
  final PoiCategory category;
  final String name;
  final double latitude;
  final double longitude;
  final String? street;
  final String? city;
  final String? description;
  final Map<String, Object?> services;
  final String? source;
  final DateTime? updatedAt;
}
```

Non mostrare marker senza nome quando il dataset dispone del nome.

Mostrare:

* nome;
* categoria;
* indirizzo;
* comune;
* distanza;
* servizi;
* coordinate;
* fonte;
* ultimo aggiornamento;
* apri indicazioni.

## Importazione POI

Supportare un formato versionato e validato.

Preferire:

* JSON compresso;
* NDJSON;
* GeoJSON;
* SQLite preconfezionato solo se compatibile e verificato.

Per importazioni grandi:

* elaborazione a batch;
* transazione;
* progresso;
* rollback in caso di errore;
* non bloccare la UI;
* sostituzione atomica del pacchetto precedente.

## Filtri

Rendere realmente funzionanti:

* Tutti;
* aree sosta;
* campeggi;
* parcheggi;
* acqua;
* scarico;
* GPL;
* assistenza.

La lista passata alla mappa deve essere già filtrata.

Il clustering già presente deve continuare a funzionare.

## Stato offline reale

La card deve mostrare:

```text
Mappa offline — Nord Italia
Versione: 2026.06
Dimensione: ...
Ultimo controllo: ...
POI installati: ...
Stato: disponibile offline
```

Mostrare stato installato soltanto se:

* file PMTiles presente;
* hash valido;
* record InstalledResource valido;
* sorgente apribile.

## Fallback

Quando offline:

* usare la mappa installata;
* usare POI locali;
* non mostrare errori di rete ripetuti;
* indicare quando una regione non è disponibile.

Quando online ma senza pacchetto:

* usare la mappa online esistente;
* non fingere copertura offline.

## Test

* attivazione regione;
* file mancante;
* hash errato;
* import POI;
* rollback;
* aggiornamento pacchetto;
* filtri;
* bounds query;
* clustering;
* fallback online/offline;
* eliminazione regione;
* widget stato installazione.

## Criteri di completamento

* almeno un pacchetto PMTiles di test locale viene aperto;
* POI locali sono consultabili senza rete;
* filtri e cluster funzionano;
* aggiornamento non elimina prematuramente la versione precedente;
* eliminazione libera spazio;
* nessuna card dimostrativa falsa.

## Commit

`feat(map): add verified offline maps and POI packages`
