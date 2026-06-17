# STEP 6 — Offline Content Core

## Obiettivo

Creare l'infrastruttura comune per contenuti scaricabili e aggiornabili:

- manifest versionato;
- catalogo locale;
- download verificato;
- registro dei contenuti installati;
- aggiornamenti;
- riconciliazione database/file system;
- gestione dello spazio;
- sicurezza dei download.

Questo step non deve ancora visualizzare mappe PMTiles o importare POI.

## Scope principale

Leggere soltanto:

- configurazione del download manager già esistente;
- servizi di storage;
- database Drift;
- Riverpod provider collegati ai download;
- schermata o sezione dei contenuti offline;
- impostazioni relative a rete e archiviazione.

Non leggere mappe, planner, documenti, diario o altre feature salvo dipendenza diretta.

## Pattern da adattare

Adattare in Dart i concetti di Project N.O.M.A.D.:

- manifest remoto validato;
- copia locale del manifest;
- fallback alla copia locale quando offline;
- risorse identificate da ID e versione;
- registro dei file installati;
- riconciliazione fra record, download e file reali;
- sostituzione atomica delle versioni;
- eliminazione della vecchia versione solo dopo la verifica della nuova;
- stima dello spazio prima del download;
- stati espliciti e recuperabili.

Repository di riferimento:

https://github.com/Crosstalk-Solutions/project-nomad

Non copiare moduli TypeScript o React. Reimplementare i pattern in Dart.

## Modelli suggeriti

```dart
enum OfflinePackageType {
  map,
  poiDatabase,
  guide,
  manual,
  languagePack,
  checklistTemplate,
  other,
}

enum InstalledResourceStatus {
  installing,
  installed,
  updateAvailable,
  missing,
  corrupted,
  failed,
}

class OfflinePackage {
  const OfflinePackage({
    required this.id,
    required this.type,
    required this.version,
    required this.title,
    required this.url,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256,
    this.description,
    this.metadata = const {},
  });

  final String id;
  final OfflinePackageType type;
  final String version;
  final String title;
  final String? description;
  final Uri url;
  final String fileName;
  final int sizeBytes;
  final String sha256;
  final Map<String, Object?> metadata;
}

class OfflineManifest {
  const OfflineManifest({
    required this.schemaVersion,
    required this.updatedAt,
    required this.packages,
  });

  final int schemaVersion;
  final DateTime updatedAt;
  final List<OfflinePackage> packages;
}
```

## Contratti suggeriti

```dart
abstract interface class OfflineManifestRepository {
  Future<OfflineManifest> loadManifest();
  Future<OfflineManifest?> loadCachedManifest();
  Future<void> cacheManifest(OfflineManifest manifest);
}

abstract interface class InstalledResourceRepository {
  Stream<List<InstalledResource>> watchAll();
  Future<InstalledResource?> findByPackageId(String packageId);
  Future<void> upsert(InstalledResource resource);
  Future<void> delete(String packageId);
  Future<ReconciliationReport> reconcile();
}

abstract interface class StorageInspector {
  Future<int> getAvailableBytes();
  Future<int> getUsedBytesByCategory(OfflinePackageType type);
  Future<StorageProjection> projectInstallation(
    Iterable<OfflinePackage> packages,
  );
}
```

## Drift

Creare o adattare una tabella equivalente a:

```dart
class InstalledResources extends Table {
  TextColumn get packageId => text()();
  TextColumn get type => text()();
  TextColumn get version => text()();
  TextColumn get localPath => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get installedSha256 => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get installedAt => dateTime().nullable()();
  DateTimeColumn get lastVerifiedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {packageId};
}
```

Non creare un secondo database.

Aggiungere migrazione compatibile con i dati esistenti.

## Manifest

Supportare almeno:

```json
{
  "schemaVersion": 1,
  "updatedAt": "2026-06-17T00:00:00Z",
  "packages": []
}
```

Validare:

* schema;
* ID univoci;
* URL HTTPS;
* nome file;
* dimensione non negativa;
* SHA-256;
* tipo supportato;
* versione.

Se il manifest remoto fallisce:

* usare quello locale;
* mostrare che il catalogo potrebbe non essere aggiornato;
* non restituire silenziosamente una lista vuota.

## Sicurezza download

Applicare:

* solo HTTPS in produzione;
* allowlist configurabile dei domini;
* blocco di path traversal;
* nome file sanificato;
* verifica MIME;
* verifica dimensione;
* verifica SHA-256;
* limite massimo configurabile;
* file temporaneo;
* rename atomico dopo verifica;
* eliminazione dei file parziali;
* nessun log di URL contenenti token.

ID download suggerito:

```dart
String buildDownloadTaskId(OfflinePackage package) {
  final source = '${package.id}|${package.version}|${package.url}';
  return sha256.convert(utf8.encode(source)).toString().substring(0, 24);
}
```

## Riconciliazione

Gestire:

* record presente ma file mancante;
* file presente ma record assente;
* hash differente;
* download terminato ma non registrato;
* versione precedente orfana;
* file temporaneo abbandonato;
* task downloader perso;
* aggiornamento interrotto.

Non eliminare automaticamente file sconosciuti senza una regola sicura.

## Gestione spazio

Mostrare:

* spazio disponibile;
* spazio attualmente usato;
* dimensione dei pacchetti selezionati;
* spazio residuo previsto;
* avviso sopra 75%;
* avviso critico sopra 90%;
* blocco se lo spazio è insufficiente.

Suddividere almeno:

* mappe;
* POI;
* guide;
* documenti;
* foto;
* cache.

## Test

Aggiungere:

* parser manifest;
* validazione manifest;
* fallback cache;
* ID deterministico;
* hash corretto e errato;
* riconciliazione;
* sostituzione versione;
* spazio insufficiente;
* file temporaneo;
* migrazione Drift;
* provider Riverpod;
* widget della proiezione spazio.

## Criteri di completamento

* catalogo disponibile online e offline;
* file verificati prima di essere installati;
* stato installato corrispondente al file reale;
* aggiornamenti riconosciuti;
* spazio stimato prima del download;
* riconciliazione idempotente;
* nessuna falsa cache offline;
* test pertinenti superati.

## Commit

`feat(offline): add versioned offline content core`
