# STEP 9 — Backup, esportazione e importazione

## Obiettivo

Garantire portabilità e recupero dei dati.

Funzioni:

- backup completo;
- ripristino;
- esportazione JSON;
- PDF;
- CSV;
- archivio ZIP;
- condivisione tramite strumenti di sistema.

GPX dettagliato sarà implementato nello STEP 12.

## Scope

Leggere soltanto:

- database Drift;
- storage documenti;
- foto;
- profilo mezzo;
- viaggi;
- manutenzione;
- spese;
- impostazioni;
- servizi export già presenti.

## Formato backup

Creare un archivio versionato:

```text
camperboss_backup_2026-06-17.zip
  manifest.json
  data/
    vehicles.json
    trips.json
    checklist.json
    journal.json
    maintenance.json
    documents.json
    expenses.json
    bookings.json
  files/
    documents/
    thumbnails/
    journal/
```

Manifest:

```json
{
  "format": "camperboss-backup",
  "schemaVersion": 1,
  "appVersion": "...",
  "createdAt": "...",
  "files": [
    {
      "path": "data/vehicles.json",
      "sha256": "..."
    }
  ]
}
```

## Contratti suggeriti

```dart
abstract interface class BackupService {
  Future<BackupResult> createBackup(BackupOptions options);
  Future<BackupInspection> inspectBackup(String path);
  Future<RestoreResult> restoreBackup(
    String path,
    RestoreStrategy strategy,
  );
}

enum RestoreStrategy {
  replaceAll,
  merge,
}
```

## Regole ripristino

Prima di importare:

1. validare archivio;
2. validare manifest;
3. verificare hash;
4. verificare schema;
5. mostrare anteprima;
6. mostrare numero di record e file;
7. creare backup automatico dello stato corrente;
8. importare in transazione;
9. copiare file in area temporanea;
10. rendere definitivo solo dopo successo.

In caso di errore:

* rollback database;
* eliminare file temporanei;
* mantenere i dati precedenti.

## Merge

Usare ID stabili.

Gestire:

* record nuovo;
* record identico;
* record più recente;
* conflitto;
* file duplicato;
* file mancante.

Non sovrascrivere silenziosamente dati più recenti.

## Privacy

La prima versione può creare backup non cifrati soltanto se:

* viene indicato chiaramente;
* l'utente sceglie esplicitamente la destinazione;
* non viene caricato automaticamente sul cloud.

Non dichiarare il backup cifrato se non lo è.

Predisporre un'interfaccia futura:

```dart
abstract interface class BackupCipher {
  Future<File> encrypt(File source, String password);
  Future<File> decrypt(File source, String password);
}
```

Non implementare crittografia improvvisata.

## PDF

Creare esportazioni leggibili per:

* dati del mezzo;
* storico manutenzione;
* viaggio;
* budget;
* checklist;
* prenotazioni.

Il PDF viaggio può contenere:

* titolo e date;
* tappe;
* prenotazioni;
* budget;
* checklist selezionate;
* contatti;
* note.

Non includere automaticamente documenti personali sensibili.

## CSV

Esportare:

* rifornimenti;
* spese;
* manutenzioni;
* chilometraggi.

Usare UTF-8 e intestazioni localizzate oppure un formato macchina stabile documentato.

## Test

* manifest;
* hash;
* archivio valido;
* archivio corrotto;
* schema non supportato;
* replace;
* merge;
* rollback;
* file mancante;
* record duplicato;
* PDF;
* CSV;
* backup grande con fixture ridotta;
* provider e UI.

## Criteri di completamento

* backup creato e ispezionabile;
* ripristino transazionale;
* nessuna perdita in caso di errore;
* allegati inclusi;
* PDF e CSV funzionanti;
* nessun upload automatico.

## Commit

`feat(data): add backup restore and export tools`
