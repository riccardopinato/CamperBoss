# STEP 10 — Guide offline e onboarding

## Obiettivo

Usare Offline Content Core per distribuire:

- guide;
- normative;
- emergenze;
- manuali;
- modelli di checklist;
- pacchetti regionali.

Creare inoltre un onboarding che configuri l'app usando i servizi già esistenti.

## Scope

Leggere soltanto:

- Offline Content Core;
- download manager;
- profilo mezzo;
- impostazioni;
- localizzazione;
- permessi posizione/notifiche;
- schermate guide;
- onboarding esistente.

## Tipi di contenuto

Supportare:

```dart
enum GuideContentType {
  markdown,
  html,
  pdf,
  json,
}
```

Esempi pacchetti:

```text
CamperBoss Essential
Italia
Europa
Emergenze
Manutenzione base
Checklist viaggio
```

Non distribuire contenuti senza verificarne licenza e attribuzione.

## Manifest

Riutilizzare OfflinePackage.

Metadata suggeriti:

```json
{
  "language": "it",
  "countryCodes": ["IT"],
  "contentType": "markdown",
  "category": "regulations",
  "requiresPro": false
}
```

## Visualizzatore guide

Supportare:

* indice;
* ricerca;
* preferiti;
* ultimo punto letto;
* collegamenti interni;
* immagini locali;
* modalità offline;
* attribuzione;
* versione e data aggiornamento.

Non eseguire JavaScript arbitrario dentro HTML scaricato.

Sanificare HTML.

## Pacchetti a livelli

Supportare collezioni dichiarative:

```dart
class ContentCollection {
  final String id;
  final String title;
  final List<String> packageIds;
  final String? includesCollectionId;
}
```

Evitare cicli.

Calcolare:

* non installata;
* parzialmente installata;
* installata;
* aggiornamento disponibile.

## Onboarding

Passaggi suggeriti:

```text
1. Lingua e Paese
2. Tipo di mezzo
3. Dimensioni e peso
4. Chilometraggio
5. Permesso posizione
6. Promemoria
7. Documenti iniziali
8. Regioni offline
9. Pacchetti guide
10. Checklist iniziale
```

L'onboarding deve:

* essere interrompibile;
* salvare il progresso;
* poter essere ripreso;
* consentire "salta";
* non chiedere tutti i permessi al primo frame;
* spiegare il motivo prima della richiesta;
* delegare ai servizi esistenti;
* non duplicare logica di salvataggio.

## Modello suggerito

```dart
class OnboardingProgress {
  final int schemaVersion;
  final Set<String> completedStepIds;
  final String? currentStepId;
  final bool completed;
}
```

## Personalizzazione

Al termine:

* dashboard legata al mezzo;
* unità metriche corrette;
* categorie rilevanti;
* reminder iniziali;
* pacchetti scelti;
* checklist predefinita.

Non avviare download pesanti senza conferma finale.

## Test

* parsing guide;
* sanificazione HTML;
* stato collezione;
* ciclo collezioni;
* preferiti;
* progresso lettura;
* onboarding ripreso;
* step saltato;
* permesso negato;
* nessun download automatico;
* localizzazione;
* widget stepper.

## Criteri di completamento

* almeno un pacchetto guida di test installabile;
* guide consultabili offline;
* attribuzione visibile;
* onboarding persistente;
* permessi contestuali;
* nessun contenuto o download fittizio.

## Commit

`feat(content): add offline guides and guided onboarding`
