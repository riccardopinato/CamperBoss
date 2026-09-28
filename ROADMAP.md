# CamperBoss Development Roadmap

## Regole

- Deve esistere un solo step `CURRENT`.
- Codex deve operare esclusivamente sullo step `CURRENT`.
- Gli step futuri devono rimanere sintetici.
- Al termine corretto, aggiorna lo stato da `CURRENT` a `DONE`.
- Registra risultato, test e commit in massimo tre righe.
- Promuovi automaticamente il primo step successivo `TODO` a `CURRENT`, ma non implementarlo nello stesso task.
- Se lo step non puo essere completato, impostalo `BLOCKED` e annota il motivo. Un nuovo `CURRENT` puo essere promosso soltanto con autorizzazione esplicita dell'utente quando sostituisce o aggira in modo documentato il blocco.

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

Stato: `DONE`

Creare storico persistente per olio, filtri, revisione, tagliando, gas, estintore, pneumatici, batterie, distribuzione, AdBlue, infiltrazioni e voci personalizzate.

Ogni intervento deve gestire:

- data, km, costo, esecutore, note e allegati;
- intervallo temporale o chilometrico;
- prossima scadenza;
- stato regolare, in scadenza o scaduto;
- modifica, eliminazione e cronologia.

Predisporre soltanto l'architettura per future notifiche.

Esito:

- Risultato: storico manutenzione persistente con CRUD, intervalli, prossime scadenze, stati e allegati locali.
- Test: `flutter analyze`; `flutter test test/maintenance_screen_test.dart test/data_models_test.dart --timeout=30s`.
- Commit: `feat: add vehicle maintenance history`.

## STEP 6 — Offline Content Core

Stato: `DONE`
Spec: `docs/roadmap/step-06-offline-content-core.md`

Esito:

- Risultato: core offline implementato con manifest versionato, cache, registro installati, sicurezza download, riconciliazione e proiezione spazio.
- Test: `flutter analyze`; `flutter test`; test mirati download/offline/map/POI.
- Commit: `feat(offline): add versioned offline content core` + verifica `test: unblock offline steps verification`.

## STEP 7 — Mappe e POI offline

Stato: `BLOCKED`
Spec: `docs/roadmap/step-07-offline-maps-poi.md`

Esito:

- Risultato: repository regioni offline e POI locali implementati; mappa usa POI offline quando presenti e mostra stato reale regioni PMTiles.
- Test: `flutter analyze`; `flutter test`; test mirati map/POI passati.
- Commit: `feat(map): add verified offline maps and POI packages`; resta da verificare apertura PMTiles reale.

## STEP 8 — Carburante, costi, budget e prenotazioni

Stato: `DONE`
Spec: `docs/roadmap/step-08-costs-budget-bookings.md`

Esito:

- Risultato: dominio finanza locale completato con rifornimenti, spese, budget viaggio, prenotazioni, reminder e dashboard dedicate collegate a planner e profilo.
- Test: `flutter analyze` mirato; `flutter test test/finance_summary_service_test.dart test/finance_screen_test.dart test/reminders_test.dart`.
- Commit: `feat(finance): add fuel expenses trip budgets and bookings`.

## STEP 9 — Backup, esportazione e importazione

Stato: `DONE`
Spec: `docs/roadmap/step-09-backup-export-import.md`

Esito:

- Risultato: servizio backup ZIP versionato con manifest/hash, ispezione, restore replace/merge, rollback logico, export PDF e CSV locali.
- Test: `flutter analyze lib/core/services/data_backup_service.dart test/data_backup_service_test.dart`; `flutter test test/data_backup_service_test.dart`.
- Commit: `feat(data): add backup restore and export tools`.

## STEP 10 — Guide offline e onboarding

Stato: `DONE`
Spec: `docs/roadmap/step-10-offline-guides-onboarding.md`

Esito:

- Risultato: guide offline installabili e consultabili con ricerca, preferiti, progresso lettura e onboarding guidato persistente con permessi contestuali e conferma finale.
- Test: `flutter analyze lib/features/onboarding/presentation/guided_onboarding_screen.dart test/guided_onboarding_screen_test.dart`; `flutter test test/offline_guides_service_test.dart test/onboarding_service_test.dart test/guided_onboarding_screen_test.dart`.
- Commit: `feat(content): add offline guides and guided onboarding`.

## STEP 11 — Ricerca locale e architettura AI-ready

Stato: `DONE`
Spec: `docs/roadmap/step-11-local-search-ai-ready.md`

Esito:

- Risultato: ricerca locale privata con indice rebuildable, sinonimi camper, filtri, snippet, recovery da indice corrotto, UI globale e contratti AI disabilitati.
- Test: `flutter analyze` mirato; `flutter test test/local_search_index_test.dart test/local_search_screen_test.dart`.
- Commit: `feat(search): add private local full text search`.

## STEP 12 — GPX, ricordi e statistiche di viaggio

Stato: `DONE`
Spec: `docs/roadmap/step-12-gpx-memories-statistics.md`

Esito:

- Risultato: storico viaggio completato con import/export GPX, ricordi geolocalizzati con conferma EXIF, statistiche derivate, vista dedicata e integrazione backup locale.
- Test: `flutter analyze` mirato; `flutter test test/gpx_service_test.dart test/travel_history_statistics_service_test.dart test/travel_history_screen_test.dart test/data_backup_service_test.dart`.
- Commit: `feat(history): add GPX travel memories and statistics`.


## STEP 13 — Product Truth Cleanup + Shell V2

Stato: `DONE`

Obiettivo:

- eliminare l'inserimento automatico di viaggi, diario, checklist e POI demo;
- sostituire la Home dimostrativa con un cockpit basato soltanto su dati locali reali;
- introdurre Boss Readiness deterministico senza inventare valori mancanti;
- ridurre la navigazione primaria da undici a cinque aree;
- mantenere tutte le funzioni secondarie raggiungibili tramite hub contestuali;
- introdurre tema light/dark coerente con il sistema;
- aggiornare documentazione e CI.

Criteri di completamento:

- nessun dato demo viene salvato automaticamente;
- Home non mostra acqua, gas, batteria, payload o score inventati;
- Boss Readiness resta non disponibile finche la copertura dati e insufficiente;
- tab primarie: Home, Mappa, Viaggi, Camper, Altro;
- `flutter analyze` e `flutter test` passano in CI;
- nessuna perdita di accesso a documenti, manutenzione, ricerca, offline, notifiche, checklist, diario e finanza.

Esito:

- Risultato: dati demo automatici rimossi, Home basata su dati reali, Boss Readiness deterministico, shell ridotta a 5 aree, hub contestuali e tema sistema light/dark.
- Test: GitHub Actions `flutter analyze` PASS; suite `flutter test` PASS.
- PR: #1 `Step 13: product truth cleanup and shell v2`.

## STEP 14 — Map Engine V2 + offline reale

Stato: `DONE`

Creare un proof of concept isolato del nuovo motore cartografico, con priorita a
MapLibre per vector tiles, layer POI, clustering e regioni offline. Riutilizzare
i pattern gia sviluppati in TrailPath, senza copiare ciecamente codice e senza
rimuovere `flutter_map` finche il POC non supera Android, iOS e Web.

Lo Step 7 resta la documentazione storica del primo tentativo PMTiles ed e
considerato assorbito dal nuovo Map Engine V2. La certificazione runtime con
rete disattivata resta un gate esplicito del Release Core: la CI ha validato
Android APK, iOS device build e Web, ma non sostituisce una prova fisica offline.

Esito:

- MapLibre V2 isolato introdotto senza rimuovere `flutter_map`;
- POI/cluster e regioni native offline Android/iOS implementati;
- `flutter analyze` e `flutter test` PASS;
- Android APK, iOS device release e Web release PASS;
- validazione fisica offline mantenuta come gate pre-release, non come blocco allo sviluppo successivo.

## STEP 15 — Routing camper-aware

Stato: `DONE`

Collegare il profilo mezzo al routing tramite un adapter dedicato. Usare
lunghezza, larghezza, altezza e massa soltanto quando il provider supporta
restrizioni compatibili. Mostrare sempre che il risultato dipende dalla qualita
dei dati stradali e non costituisce garanzia di transitabilita.

Esito:

- profilo mezzo tradotto in restrizioni ORS `driving-hgv`;
- lunghezza/larghezza/altezza in metri e massa massima in tonnellate;
- fallback `driving-car` senza profilo valido;
- fingerprint route include le dimensioni del mezzo;
- UI mostra stato camper-aware e valori realmente applicati;
- `flutter analyze` PASS e suite `flutter test` PASS.

## STEP 16 — Release Core

Stato: `BLOCKED`

Obiettivi:

- eliminare paywall, piani e CTA di acquisto finti;
- mantenere un boundary di entitlement provider-agnostic, senza scegliere ora RevenueCat o altri provider;
- privacy/backup Android e iOS verificati per documenti e dati sensibili;
- localizzazione completa, inclusa opzione lingua Sistema/Automatico;
- CI/release checks, AppLab/device QA e size audit;
- hardening degli stati offline, errore e recovery;
- deploy Web stabile per la verifica da PC.

Implementato:

- monetizzazione reale rinviata per decisione di prodotto; nessun SDK di billing/RevenueCat incluso nel Release Core;
- interfaccia di entitlement neutra mantenuta dormiente per il futuro, senza piani o checkout esposti nella UI;
- download mappe offline non bloccato da un paywall prematuro;
- lingua Sistema/Automatico e cataloghi IT/EN/DE/FR/ES/PT allineati;
- backup Android disabilitato per dati privati, cleartext disabilitato e data extraction rules;
- bridge iOS per escludere i documenti privati dal backup cloud automatico;
- deploy Web Pages stabile;
- build gate Android/iOS/Web e audit dimensioni bundle;
- test di parita traduzioni e comportamento monetizzazione differita.

Blocchi esterni di certificazione:

- completare prova fisica MapLibre offline con rete disattivata;
- completare device/AppLab QA finale;
- GitHub Actions fallisce prima dell'assegnazione runner (nessuno step avviato), quindi analyze/test/build finali non sono certificabili finche l'account Actions non torna operativo.

Non promuovere STEP 17 finche questi gate non sono chiusi.

## STEP 17 — Local AI Micro Engine

Stato: `TODO` — non anticipare prima del Release Core.

Obiettivo futuro: valutare AI on-device facoltativa per manuali/documenti e
assistenza contestuale privata.

Vincoli iniziali:

- core dell'app sempre usabile senza AI;
- gateway astratto e modello sostituibile;
- nessun upload implicito di documenti;
- primo benchmark orientato a modelli circa <= 50 MB;
- candidato da verificare: Cactus/Needle 3 o equivalente;
- confrontare anche alternative piu recenti e leggere prima della scelta;
- misurare dimensione reale, RAM di picco, first-token latency, tokens/s,
  qualita su task CamperBoss, licenza, Android/iOS supportati e impatto APK/IPA;
- non selezionare un modello soltanto in base al numero di parametri.
