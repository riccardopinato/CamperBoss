# STEP 11 — Ricerca locale e architettura AI-ready

## Obiettivo

Creare prima una ricerca locale privata e affidabile.

Indicizzare:

- documenti e OCR;
- manutenzioni;
- note;
- viaggi;
- prenotazioni;
- guide offline;
- manuali;
- dati del mezzo.

Predisporre le interfacce per un futuro assistente AI, senza inviare documenti a servizi esterni in questo step.

## Scope

Leggere soltanto:

- database Drift;
- documenti/OCR;
- guide;
- manutenzione;
- planner;
- journal;
- repository interessati;
- schermata ricerca.

## Ricerca locale

Verificare se SQLite/Drift della piattaforma supporta FTS5.

Se FTS5 è disponibile su tutte le piattaforme target:

- usare una virtual table FTS5;
- mantenere l'indice sincronizzato.

Se il web non supporta la stessa configurazione:

- creare un adapter di ricerca;
- usare un fallback esplicito e testato;
- non rompere mobile;
- non fingere equivalenza prestazionale.

## Modelli suggeriti

```dart
enum SearchDocumentType {
  vehicleDocument,
  maintenance,
  journal,
  trip,
  booking,
  offlineGuide,
  vehicleNote,
}

class SearchDocument {
  final String id;
  final SearchDocumentType type;
  final String sourceId;
  final String title;
  final String body;
  final Map<String, String> metadata;
  final DateTime updatedAt;
}

class SearchHit {
  final String sourceId;
  final SearchDocumentType type;
  final String title;
  final String snippet;
  final double score;
}
```

## Contratto

```dart
abstract interface class LocalSearchIndex {
  Future<void> index(SearchDocument document);
  Future<void> remove(String id);
  Future<void> rebuild();
  Future<List<SearchHit>> search(
    String query, {
    Set<SearchDocumentType>? types,
    int limit = 50,
  });
}
```

## Sincronizzazione

Aggiornare l'indice quando un record viene:

* creato;
* modificato;
* eliminato;
* reimportato;
* ripristinato da backup.

Aggiungere:

* versione indice;
* rebuild;
* stato;
* progresso;
* recupero da indice corrotto.

Il database applicativo resta la fonte autorevole.

## Query

Supportare:

* parole;
* frasi;
* filtri per tipo;
* filtri per data;
* evidenziazione;
* snippet;
* ordinamento per rilevanza.

Aggiungere un piccolo dizionario di sinonimi camper:

```dart
const camperSearchAliases = {
  'libretto': ['carta di circolazione'],
  'tagliando': ['manutenzione programmata'],
  'bombola': ['gas', 'gpl'],
  'acque grigie': ['serbatoio scarico'],
};
```

Non trasformare il dizionario in logica AI.

## Privacy

* tutto locale;
* nessun upload;
* nessun log del testo completo;
* cancellazione immediata dall'indice;
* rebuild dopo restore.

## Architettura AI-ready

Creare soltanto contratti e modelli, senza integrazione remota:

```dart
class KnowledgeCitation {
  final String sourceId;
  final String title;
  final String excerpt;
}

class KnowledgeAnswer {
  final String text;
  final List<KnowledgeCitation> citations;
}

abstract interface class KnowledgeAssistantGateway {
  Future<KnowledgeAnswer> ask({
    required String question,
    required List<SearchHit> localContext,
  });
}
```

Implementazione attuale:

```dart
class DisabledKnowledgeAssistantGateway
    implements KnowledgeAssistantGateway {
  @override
  Future<KnowledgeAnswer> ask({
    required String question,
    required List<SearchHit> localContext,
  }) {
    throw const KnowledgeAssistantUnavailable();
  }
}
```

Non integrare:

* Ollama sul telefono;
* Qdrant sul telefono;
* embedding pesanti;
* OpenAI;
* upload documenti;
* backend RAG.

## UI

Creare una ricerca globale con:

* campo ricerca;
* filtri;
* risultati raggruppati;
* snippet;
* apertura della sorgente;
* empty state;
* errore indice;
* ricostruisci indice.

Nascondere l'assistente AI finché non è implementato realmente.

## Test

* indicizzazione;
* aggiornamento;
* cancellazione;
* rebuild;
* sinonimi;
* ranking;
* filtri;
* snippet;
* indice corrotto;
* backup/restore;
* provider;
* widget ricerca;
* apertura risultato.

## Criteri di completamento

* ricerca reale sul testo OCR;
* ricerca reale su guide e note;
* cancellazione coerente;
* ricostruzione indice;
* nessun dato inviato fuori dal dispositivo;
* contratti AI presenti ma funzione non mostrata.

## Commit

`feat(search): add private local full text search`
