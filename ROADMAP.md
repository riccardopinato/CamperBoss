# CamperBoss Development Roadmap

## Regole

- Puo esistere un solo step `CURRENT`.
- Codex deve operare esclusivamente sullo step `CURRENT`.
- Gli step futuri devono rimanere sintetici.
- Quando uno step diventa `CURRENT`, completa soltanto per quello:
  - obiettivo;
  - scope consentito;
  - dipendenze dirette consentite;
  - criteri di completamento;
  - test mirati.
- Al termine, aggiorna lo stato da `CURRENT` a `DONE`.
- Inserisci commit e risultato in massimo tre righe.
- Promuovi lo step successivo a `CURRENT` solo su richiesta dell'utente.
- Aggiorna le sezioni esistenti in-place: non aggiungere copie o cronologie estese.

Stati: `CURRENT`, `TODO`, `DONE`, `BLOCKED`.

## STEP 1 — Località, GPS, meteo e mappa realmente usabili

Stato: `CURRENT`

Obiettivo sintetico:

- ricerca manuale di una località;
- selezione del risultato;
- coordinate condivise;
- ricentramento della mappa;
- aggiornamento del meteo sulla località selezionata;
- pulsante "usa la mia posizione";
- gestione dei permessi GPS;
- fallback manuale quando il GPS non è disponibile.

Scope consentito:

- `lib/core/services/`: solo località, geocoding, GPS e meteo;
- `lib/core/state/`: solo stato di località, posizione e meteo;
- `lib/features/map/`;
- `lib/features/home/`: soltanto file direttamente coinvolti con località e meteo;
- `lib/shared/widgets/`: soltanto widget direttamente necessari.

Dipendenze dirette consentite:

- servizi esistenti di geocoding/meteo;
- stato condiviso della località;
- widget meteo e mappa direttamente coinvolti;
- configurazioni strettamente necessarie per permessi GPS e rete.

Criteri di completamento:

- l'utente può cercare una località manualmente;
- l'utente può selezionare un risultato;
- la mappa si ricentra sulle coordinate selezionate;
- il meteo usa la località selezionata;
- è disponibile un comando "usa la mia posizione";
- se il GPS non è disponibile, resta possibile usare la ricerca manuale;
- nessun file fuori scope viene modificato senza autorizzazione.

Test mirati:

- `flutter analyze` sui file dello step;
- test widget o unit pertinenti alla selezione località/meteo;
- eventuale build mirata solo se necessaria per permessi o piattaforma.

File già noti:

- `lib/core/services/geocoding_service.dart`;
- `lib/core/services/weather_service.dart`;
- `lib/core/state/selected_location.dart`;
- `lib/features/map/presentation/map_screen.dart`;
- `lib/features/home/presentation/home_screen.dart`;
- `lib/shared/widgets/weather_summary_card.dart`;
- `test/widget_test.dart`.

## STEP 2 — Fondazione della persistenza locale condivisa

Stato: `TODO`

Obiettivo sintetico:

- consolidare la persistenza locale esistente;
- predisporre modelli, tabelle e repository per checklist, trip e journal;
- gestire eventuali migrazioni;
- evitare modifiche alle UI delle tre feature in questo step.

Scope iniziale:

- `lib/data/database/`;
- modelli relativi a checklist, trip e journal;
- repository relativi a checklist, trip e journal;
- provider o servizi database direttamente necessari.

## STEP 3 — Checklist persistente e modificabile

Stato: `TODO`

Obiettivo sintetico:

- checkbox reali;
- aggiunta degli elementi;
- modifica ed eliminazione;
- categorie;
- salvataggio locale;
- ripristino dei dati alla riapertura.

Scope iniziale:

- `lib/features/checklist/`;
- soltanto file checklist necessari dentro `lib/data/`;
- soltanto stato/provider checklist necessario;
- widget condivisi indispensabili.

## STEP 4 — Planner viaggio editabile

Stato: `TODO`

Obiettivo sintetico:

- creazione e modifica dei viaggi;
- tappe;
- date;
- soste;
- costi;
- note;
- salvataggio locale;
- ripristino dei viaggi salvati.

Scope iniziale:

- `lib/features/trip/`;
- soltanto file trip necessari dentro `lib/data/`;
- soltanto stato/provider trip necessario;
- widget condivisi indispensabili.

## STEP 5 — Journal usabile

Stato: `TODO`

Obiettivo sintetico:

- creazione e modifica delle note di viaggio;
- data;
- luogo associato;
- chilometri;
- costi;
- cronologia;
- salvataggio locale;
- ripristino delle note.

Scope iniziale:

- `lib/features/journal/`;
- soltanto file journal necessari dentro `lib/data/`;
- soltanto stato/provider journal necessario;
- widget condivisi indispensabili.

## Aggiornamento futuro della roadmap

Dopo ogni implementazione Codex deve:

1. aggiornare lo stato dello step completato;
2. registrare in massimo tre righe risultato, test e commit;
3. non inserire diff, spiegazioni lunghe o liste complete di file;
4. non modificare il contenuto degli step futuri salvo necessità concreta;
5. non promuovere automaticamente lo step successivo a `CURRENT`;
6. attendere il comando dell'utente.
