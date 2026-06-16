# CamperBoss Development Roadmap

## Regole

- Deve esistere un solo step `CURRENT`.
- Codex deve operare esclusivamente sullo step `CURRENT`.
- Gli step futuri devono rimanere sintetici.
- Al termine corretto, aggiorna lo stato da `CURRENT` a `DONE`.
- Registra risultato, test e commit in massimo tre righe.
- Promuovi automaticamente il primo step successivo `TODO` a `CURRENT`, ma non implementarlo nello stesso task.
- Se lo step non puo essere completato, impostalo `BLOCKED`, annota il motivo e non promuovere altri step.

Stati: `CURRENT`, `TODO`, `DONE`, `BLOCKED`.

## Storico completato

- Localita, GPS, meteo e mappa realmente usabili: `DONE`.
- Fondazione della persistenza locale condivisa: `DONE`.
- Checklist persistente e modificabile: `DONE`.
- Planner viaggio editabile: `DONE`.
- Journal usabile: `DONE`.

## STEP 1 — Persistenza reale: Viaggi, Liste e Diario

Stato: `DONE`

Correggere CRUD e persistenza locale di:

- Viaggi: titolo, destinazione, date, tappe, costi e note.
- Liste: liste, categorie, elementi e checkbox.
- Diario: titolo, testo, data, luogo, km e costi.

Requisiti:

- creare, leggere, modificare ed eliminare;
- aggiornare subito la UI;
- mantenere i dati dopo cambio schermata, refresh web e riavvio mobile;
- funzionare offline e senza autenticazione;
- correggere `Trip planner unavailable` e gli stati vuoti errati;
- non usare dati dei viaggi per mostrare il diario;
- usare database/repository/provider condivisi e compatibili web/mobile;
- aggiungere test CRUD e persistenza mirati.

Esito:

- Risultato: CRUD reale e persistenza locale offline per viaggi, liste e diario su mobile con SQLite e web con localStorage.
- Test: `flutter analyze` mirato; `flutter test test/checklist_screen_test.dart test/trip_planner_screen_test.dart test/journal_screen_test.dart test/data_models_test.dart test/local_json_collection_test.dart --timeout=30s`.
- Commit: `fix: persist trips lists and journal across platforms`.

## STEP 2 — Mappa, filtri, POI e cache

Stato: `DONE`

- Rendere selezionabili e funzionanti i filtri: sosta, camping, parcheggio, acqua, scarico, GPL e assistenza.
- Aggiornare realmente marker e stato dei filtri.
- Mostrare per ogni POI, quando disponibili: nome, categoria, indirizzo, comune, coordinate, distanza, servizi, fonte e indicazioni stradali.
- Verificare `Offline cache: North Italy`.
- Se non funziona, rimuoverla.
- Se salva solo POI, rinominarla `Cache POI offline` e mostrare regione, elementi, dimensione, aggiornamento, elimina e refresh.
- Non scaricare massivamente tile dai server standard OpenStreetMap.

Esito:

- Risultato: filtri POI funzionanti, marker/lista sincronizzati, dettagli POI completi, directions reali e cache POI offline locale con refresh/elimina.
- Test: `flutter analyze` mirato; `flutter test test/map_screen_test.dart test/local_poi_cache_repository_test.dart test/data_models_test.dart --timeout=30s`.
- Commit: `feat: activate poi filters and offline cache`.

## STEP 3 — Il mio mezzo

Stato: `DONE`

Creare un profilo mezzo persistente con:

- tipologia, marca, modello, anno e targa facoltativa;
- lunghezza, larghezza, altezza, peso e massa massima;
- posti, alimentazione e chilometraggio;
- capacita carburante, acque e gas;
- autonomia elettrica e note.

Supportare creazione, modifica, validazione, salvataggio locale e ripristino.

Esito:

- Risultato: profilo mezzo persistente locale con CRUD, validazione e schermata profilo usabile.
- Test: `flutter analyze`; `flutter test test/local_vehicle_profile_repository_test.dart test/profile_screen_test.dart test/data_models_test.dart --timeout=30s`.
- Commit: `feat: add persistent vehicle profile`.

## STEP 4 — Documenti del mio mezzo

Stato: `DONE`

Creare archivio locale e privato per libretto, assicurazione, revisione, tagliando, bollo, impianto gas, manuali, fatture e altro.

Supportare:

- foto, selezione immagini/PDF e scansione quando disponibile;
- documenti multipagina;
- anteprima, categoria, nome, date, scadenza e note;
- modifica, eliminazione, ordinamento e ricerca;
- file nell'area privata dell'app e soli metadati nel database;
- comportamento compatibile con mobile e web;
- nessun upload cloud automatico.

Esito:

- Risultato: archivio documenti locale con scansione Android/iOS, import file, PDF privati, metadati persistenti e conferma OCR prima del salvataggio.
- Test: `flutter analyze`; `flutter test test/vehicle_documents_screen_test.dart test/data_models_test.dart --timeout=30s`.
- Commit: `feat: add private vehicle document archive`.

## STEP 5 — Manutenzione del mezzo

Stato: `CURRENT`

Creare storico persistente per olio, filtri, revisione, tagliando, gas, estintore, pneumatici, batterie, distribuzione, AdBlue, infiltrazioni e voci personalizzate.

Ogni intervento deve gestire:

- data, km, costo, esecutore, note e allegati;
- intervallo temporale o chilometrico;
- prossima scadenza;
- stato regolare, in scadenza o scaduto;
- modifica, eliminazione e cronologia.

Predisporre soltanto l'architettura per future notifiche.
