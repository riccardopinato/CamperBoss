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
- test di parita traduzioni e comportamento monetizzazione differita;
- stati errore offline con retry esplicito e azioni sicure;
- recovery dei download quando il sistema operativo perde il task, ricostruito solo da metadati cached compatibili;
- progetto iOS corretto con file reference esplicita per il bridge privacy;
- workflow Release Core pubblica APK ARM64 per 1 giorno e cancella run superati;
- vecchio workflow Map Engine V2 mantenuto solo manuale per evitare build duplicate;
- Step 16C Foundation Repair completato: superfici condivise theme-aware, rimozione fallback/localita simulate, Home e meteo basati solo su dati reali, setup senza profilo demo, notifiche con recovery esplicito, profilo/manutenzione/documenti hardenizzati, conferme distruttive e pulizia delle etichette debug della Mappa;
- Step 16D Core Functional Repair completato: MapLibre unificato, persistenza viewport/offline, planner e storico su MapLibre, tappe strutturate/geocodificate, cancellazione viaggio a cascata, statistiche multicurrency corrette, allegati manutenzione reali, deep-link ricerca locale;
- Step 16E Offline & System Integration completato: service graph condiviso, verita offline basata su regione completa + viewport persistito, verifica pacchetti guide, reminder centralizzati, indice ricerca auto-refresh e audit integrita cross-domain;
- Step 16F UX & Product Polish completato: Home first-run, Smart Map map-first, editor Camper/Viaggio progressivi, griglie responsive e rimozione duplicazioni di navigazione;
- cataloghi IT/EN/DE/FR/ES/PT riallineati e test di parita aggiornati;
- Step 16G automated certification completata sul commit app `e88d586fc41e31c5175050f7934a383e5e480c1d`: `flutter analyze` PASS, `flutter test` 113/113 PASS, Android ARM64 release PASS, iOS release no-codesign PASS, Web release PASS, privacy assertions PASS;
- artifact Android `camperboss-arm64-release-apk`, ID `11229115224`, APK `48,029,264` byte (~45.8 MiB), sotto la soglia warning 80 MiB;
- iOS `Runner.app` ~82 MiB (`flutter` report 85.3 MB); Web release ~43 MiB;
- evidence bundle: `docs/release/step-16g-evidence.md`.

Blocchi esterni di certificazione:

- completare prova fisica MapLibre offline: scaricare una regione, riavviare l'app, disattivare la rete e verificare riapertura della regione;
- completare device/AppLab QA finale su Android/iPhone/Web secondo `docs/release/release-core-checklist.md`.

Step 16 resta `BLOCKED`. L'audit Master v20 / Golden Rules del 2026-10-03 ha riaperto anche gate tecnici e di governance oltre ai gate manuali: Product Truth/main, backup e data safety, POI/offline truth, supply-chain/delivery, localizzazione, privacy/licenze, performance e QA runtime. I dettagli sono in `docs/audit/master-v20-heavy-audit-2026-10-03.md`. Non promuovere STEP 17 finché STEP 16J–16Q e i gate device/AppLab non sono chiusi.

## STEP 16H — Master v20 Factory Hardening

Stato: `BLOCKED`

Obiettivo:

- allineare CamperBoss alla gerarchia Master Prompt v20 senza riscrivere il core già certificato;
- registrare provenienza e riuso di Golden/donor/OSS;
- introdurre configurazione CodeRabbit Flutter per review PR;
- predisporre Fastlane con pipeline Android build-once verso Play Internal Testing;
- correggere il restore dei file fisici nel backup, mantenendo safety snapshot e rollback;
- estendere l'Evidence Bundle senza anticipare STEP 17.

Vincoli:

- nessun merge della catena STEP 16 finché i gate manuali Release Core restano aperti;
- nessuna chiave o service-account nel repository;
- Play delivery attivabile solo con signing key e service account configurati;
- CodeRabbit e Fastlane restano integrazioni verificabili, non sostituti di analyze/test/build;
- nessuna ricerca OSS retroattiva artificiale quando esiste già un donor interno appropriato.

Esito audit 2026-10-03:

- implementazione candidata presente in `step-16h-master-v20-hardening`; Flutter CI e build Android/iOS/Web risultano verdi;
- CodeRabbit carica la configurazione, ma il gate di review non è ancora certificato end-to-end sulla catena finale;
- la lane Fastlane/Play non è stata eseguita e va corretta/verificata la discovery del `Fastfile` sotto `android/fastlane`;
- Play Internal Testing resta bloccato da secret/signing/service account e dalla policy di versionCode;
- i difetti di backup/data safety emersi dall'audit sono spostati nello STEP 16K.

## STEP 16I — Lifecycle & Media Safety

Stato: `DONE`

Obiettivo:

- applicare il Batch Data Safety audit ai file locali realmente posseduti dall'app;
- impedire cancellazioni premature quando più entità condividono lo stesso file;
- rimuovere file orfani quando un documento, una manutenzione, una memoria o una traccia sostituisce/rimuove un allegato;
- far passare anche restore/merge backup attraverso i boundary di lifecycle dei media;
- formalizzare una policy entity-by-entity per hard delete, archive, trash e purge senza introdurre soft-delete indiscriminato.

Scope:

- Vehicle Documents: cleanup reference-safe su update/delete;
- Maintenance: cleanup reference-safe su update/delete;
- Travel History: cleanup reference-safe di foto e GPX condivisi;
- Backup/Restore: lifecycle dei media coordinato tramite TravelHistoryService;
- regression tests dedicati per shared GPX e foto condivise.

Vincolo:

- non viene dichiarato un Universal Trash implementato; il cestino resta una scelta di prodotto da applicare solo alle entità per cui restore/undo crea valore reale.

Esito:

- cleanup reference-safe implementato per documenti, manutenzione, foto Memories e GPX condivisi;
- backup restore instradato attraverso il lifecycle media; test regression aggiunti;
- Flutter CI e Release Core Android/iOS/Web PASS sul commit `3bec9e5857dad94258d0cff32dfa23beba336417`;
- i gap più ampi di atomicità, Trash/Restore e referential integrity sono riaperti nello STEP 16K.

## STEP 16J — Product Truth, governance e baseline di release

Stato: `DONE`

Fonte: audit Master Prompt v20 / Golden Rules 2026-10-03.

Obiettivi bloccanti:

- riallineare `main`, oggi fermo allo STEP 15, con la catena validata STEP 16D→16I solo dopo i gate previsti; eliminare/chiudere la vecchia PR #4 e consolidare la catena #5→#10 senza blind merge;
- impedire che la Web Preview venga presentata come attuale finché GitHub Pages continua a deployare esclusivamente `main` stale;
- correggere Product Truth documentale: `AGENTS.md`, `README.md`, `PENDING_ISSUES.md`, `docs/IMPLEMENTATION_STATUS.md` e ROADMAP devono descrivere l'implementazione reale e la gerarchia Master v20;
- rimuovere la contraddizione REUSE-FIRST vs la regola legacy “non copiare moduli esterni; reimplementa” in `AGENTS.md`;
- verificare/proteggere `main` con required checks/review/no direct release pushes; nessun ruleset repository è attualmente configurato, mentre la branch protection classica resta da verificare;
- chiudere il gate CodeRabbit sulla PR finale e registrare review/evidence reali;
- fare repository-hygiene audit del repo pubblico: dossier, estratti, `chat con grok.txt`, mock/demo residui e materiale che non deve essere pubblico;
- mantenere una sola voce `CURRENT` e registrare esplicitamente le eccezioni autorizzate dall'utente alla sequenza degli step.

Criterio di uscita:

- una baseline canonica, tracciabile e coerente tra Master/Product Truth, repository, PR stack, `main`, Pages ed Evidence Bundle.

Esito 2026-10-03:

- Product Truth riallineata in AGENTS/README/IMPLEMENTATION_STATUS/PENDING_ISSUES e dossier audit; residui non necessari rimossi dal candidate tree;
- vecchia PR STEP 16 Release Core chiusa come superseded; PR stack corrente mantenuta senza merge prematuro;
- ruleset repository assenti; branch-protection classica non verificabile dal connector e resta gate di enforcement finale nello STEP 16Q;
- autorizzazione utente registrata per esecuzione sequenziale 16J→16Q.

## STEP 16K — Backup Recovery v2 + atomicità + lifecycle dati

Stato: `DONE`

Problemi da risolvere tutti:

- il restore `replaceAll` e le cascade cross-domain sono sequenze di repository, non una singola transazione/unit-of-work atomica come richiesto dalla spec STEP 9;
- creare una UI reale Backup/Inspect/Restore/Export raggiungibile dall'app: oggi `DataBackupService` non costituisce una feature utente completa;
- includere nel backup le impostazioni e gli stati utente mancanti o dichiararli esplicitamente fuori scope: reminder settings, preferenza lingua, onboarding, guide favorites/progress, map state e altri state store rilevanti;
- correggere il leak del merge: i file fisici materializzati per record poi `skipped` non devono rimanere orfani;
- il restore legacy schema v1 non deve saltare silenziosamente file ambigui/non mappabili lasciando path del device sorgente;
- aggiungere staging completo, validazione di ogni path referenziato, commit/rollback verificabile e post-restore integrity audit;
- gestire backup grandi senza caricare ZIP, documenti e foto interamente in RAM; aggiungere progress/cancel/size guard e stress test;
- applicare la stessa protezione all'export ZIP foto e ai GPX di grandi dimensioni;
- rendere atomica o recuperabile la cancellazione viaggio con finance/history/media/route;
- impedire dangling `document_id` in spese, carburante e prenotazioni quando si elimina un documento;
- estendere `DataIntegrityService` a GPX/Memories→Trip, route preview→Trip, budget→Trip, reminder→source, media path, offline registry e duplicate identity mancanti;
- rimuovere reminder repository stale durante `reconcile`: oggi le sorgenti eliminate possono lasciare record locali e in alcuni flussi essere rischedulate;
- serializzare/controllare le write read-modify-write di `LocalJsonCollection` e map state sul Web per evitare lost update concorrenti;
- definire e implementare entity-by-entity hard delete / archive / Trash / Restore / Purge per Trip, Documenti, Manutenzione, Journal e Memories; niente soft-delete indiscriminato;
- certificare i contratti Golden Batch Data Safety: Trash preserva media, Purge abilita GC, backup include il lifecycle scelto, restore usa staging + validation + safety snapshot + commit.

Criterio di uscita:

- nessuna perdita o orphan silenzioso in restore/merge/delete, recovery testata anche su failure injection e dataset grandi.

Esito:

- Backup Recovery v3: remap file rigoroso, safety snapshot/rollback, cleanup orfani, state backup, integrity audit post-restore, streaming/progress/cancel e guard dimensionale; cascade viaggio recuperabile, document delete protetto da riferimenti, reminder canonici e write locali serializzate.
- Test: Flutter CI `37115776142` PASS sul commit `cffb9aa37f5f49ffa2b87e2817d65e45bf1a17af`; regression dedicate a concorrenza, stale reminders, rollback cascade e document references.
- PR: #12 `STEP 16K: Data Safety & Recovery v2`; nessun merge eseguito.

## Sequenza consigliata per chiudere il Release Core

1. **16L — Map/POI/Offline:** correggere prima le capability che l'utente usa direttamente e che oggi hanno ancora Product Truth incompleta.
2. **16M — Delivery:** rendere CI/build/versioning deterministici prima di produrre altri candidate artifact.
3. **16N — UX/platform parity:** localizzazione, accessibilità, iOS/Web e branding dopo che i flussi core sono stabili.
4. **16O — Trust boundaries:** chiudere provider, privacy, licenze e routing production boundary senza aggiungere account/cloud obbligatori.
5. **16P — Performance:** misurare la baseline finale con AppLab e stress test; eventuali regressioni tornano allo step proprietario.
6. **16Q — Certification:** una sola matrice completa AppLab/device/Web, release PR canonica verso `main`, Pages e verdetto finale.

Regola operativa: correggere automaticamente i problemi software riproducibili; lasciare `BLOCKED` solo ciò che richiede hardware, credenziali/store o verifica legale esterna. Non avviare STEP 17 AI finché 16Q non chiude il Release Core.

## STEP 16L — Map / POI / Offline Product Truth

Stato: `DONE`

Priorità: chiudere prima la verità del prodotto cartografico, poi certificare offline/storage. Non aggiungere nuove feature mappa finché questa base non è affidabile.

### 16L-A — POI production supply

- una fresh install deve avere un percorso reale e documentato per ottenere POI, oppure la UI deve dichiarare chiaramente che nessun catalogo è installato;
- introdurre un adapter provider-neutral per catalogo POI, manifest/versione, attribution, update e import atomico;
- scegliere la sorgente produttiva solo dopo verifica di licenza/caching/distribuzione nello STEP 16O;
- nessun dataset demo o fixture nel runtime; `mock_camper_repository.dart` va rimosso dal release source o confinato ai test;
- mantenere filtri e repository locale/offline già esistenti come boundary stabile.

### 16L-B — Storage/offline truth

- sostituire il budget fisso da 5 GiB con spazio libero reale del device quando la piattaforma lo consente; il budget applicativo resta una policy separata e visibile;
- unificare accounting di pacchetti offline, regioni native MapLibre e media gestiti dall'app;
- preflight prima dei download pesanti, blocco sicuro su spazio insufficiente, handling ENOSPC/interruzione e riconciliazione al riavvio;
- nessuna regione deve risultare pronta senza stato MapLibre completo + viewport persistito;
- mantenere separati cache temporanea, contenuti installati e file utente.

### 16L-C — Map semantics + runtime harness

- eliminare distanza fittizia dal centro tecnico `42.5, 12.5`: senza posizione reale la UI mostra POI senza distanza oppure richiede un punto esplicito;
- aggiornare i flow Maestro/AppLab eliminando Lake Garda, vecchio entry point Preview e tap a coordinate fragili;
- usare AppLab `riccardopinato/AppLab` come donor/harness, baseline `6774654ba8cdf589872e11f54019b557e4ec45f0`, riusando solo i moduli necessari;
- smoke runtime mirato in questo step: launch, map load, filtri, install/cache POI, restart e recovery; la certificazione completa resta nello STEP 16Q;
- preparare il critical path offline: download regione → restart → rete off → reopen/zoom/pan, senza dichiararlo PASS finché il runtime non lo dimostra.

Criterio di uscita:

- fresh install senza demo; POI/provider truth esplicita; storage reale o fallback dichiarato; nessuna distanza inventata; flow AppLab aggiornati e smoke map/offline ripetibile.

Esito:

- Risultato: catalogo POI provider-neutral esposto nella UI senza fixture runtime; storage usa spazio device reale quando disponibile senza budget fisso implicito; MapLibre mantiene il fallback tecnico solo per il renderer e non inventa piu distanze; harness Maestro/AppLab aggiornato con policy network/restart.
- Test: regressioni widget/unit aggiornate; il push finale richiede `flutter analyze` + `flutter test` via CI. Il runtime fisico no-network resta evidence obbligatoria dello STEP 16Q e non viene dichiarato PASS qui.
- Commit: `fix(map): close STEP 16L product truth gaps`.

## STEP 16M — Supply chain, CI/CD, Fastlane e release identity

Stato: `CURRENT`

Problemi da risolvere tutti:

- ampliare i trigger PR CI da solo `ready_for_review` a opened/synchronize/reopened/ready_for_review, evitando PR aggiornate senza nuovi check;
- pin delle GitHub Actions a commit SHA approvati e processo di aggiornamento controllato;
- fissare una versione Flutter/Dart riproducibile invece del solo `channel: stable`;
- introdurre `Gemfile.lock` e risoluzione Ruby/Fastlane deterministica;
- correggere/verificare l'esecuzione Fastlane: il workflow parte dalla root mentre il `Fastfile` è sotto `android/fastlane`;
- testare la lane senza ricostruire il bundle: deve caricare lo stesso AAB hashato prodotto una sola volta;
- introdurre versioning release/versionCode monotono: `pubspec.yaml` è ancora `0.1.0+1`;
- hard-fail del percorso Play se manca release signing; il fallback debug è ammesso solo per APK QA esplicitamente marcati;
- aggiungere dependency/license audit, secret scanning e SAST/code scanning compatibili con il progetto;
- potenziare static analysis: `analysis_options.yaml` non può restare limitato a `prefer_single_quotes`;
- aggiungere coverage/integration gates, non solo analyze + unit/widget tests;
- portare retention Evidence/QA oltre 1 giorno per i candidate artifact;
- certificare Play Internal Testing con signing key, service account, track/version e hash AAB nell'Evidence Bundle.

Criterio di uscita:

- source → PR review → deterministic CI → immutable artifact → Internal Testing è riproducibile, tracciato e non usa build differenti.

## STEP 16N — Localizzazione, accessibilità, iOS capability e Web quality

Stato: `TODO`

Problemi da risolvere tutti:

- eliminare stringhe UI hard-coded in Map, MapLibre preview, Finance, Trip Planner e altre superfici; il test attuale verifica solo parità delle chiavi JSON e non copertura del codice;
- passare la lingua corrente al geocoder: oggi `GeocodingService.search` usa inglese di default;
- formattare date, numeri, distanze, valute e unità secondo locale invece di concatenazioni manuali;
- aggiungere test che intercettino literal UI non autorizzati e coverage reale IT/EN/DE/FR/ES/PT;
- correggere Product Truth documenti: la scansione documenti nativa è Android-only; iOS ha import/OCR ma non lo scanner dichiarato nello STEP 4;
- decidere/implementare una vera scansione iOS oppure correggere tutte le promesse di feature;
- rendere reale lo stato permesso notifiche su iOS: oggi `getPermissionState()` restituisce sempre `unavailable`;
- gestire in modo visibile il fallback timezone UTC invece di spostare silenziosamente i reminder;
- completare accessibility audit: screen reader, semantics, focus order, contrast, tap target, Dynamic Type/textScale 200%, dark mode e keyboard;
- correggere metadati Web/PWA ancora da template (“A new Flutter project”, `camperboss` lowercase) e valutare la forzatura `portrait-primary` per desktop/tablet;
- definire chiaramente la parità Web: import documenti/media non supportato dai current stub; non fingere feature native;
- verificare browser back/refresh/deep-link e quota/error recovery del local storage;
- allineare branding, display name, icon/splash/store assets e capitalizzazione CamperBoss;
- decidere la copertura reale della ricerca locale: oggi non indicizza expense, fuel, budget, checklist, GPX e Memories; o estenderla o descriverne correttamente lo scope.

Criterio di uscita:

- nessuna promessa di capability non vera e UX verificata su lingue, accessibilità, iOS e Web.

## STEP 16O — Security, privacy, licensing e trust boundaries

Stato: `TODO`

Problemi da risolvere tutti:

- definire strategia produttiva per OpenRouteService: una chiave passata via `--dart-define` finisce nel client e non è un secret difendibile; usare proxy/token/provider adatto a public client oppure un'altra architettura approvata;
- creare threat model formale per database, SharedPreferences/localStorage, documenti, backup e dati posizione; decidere esplicitamente se serve cifratura at-rest oltre al sandbox;
- mantenere backup OS Android disabilitato e verificare l'esclusione iOS per tutte le classi di media sensibili, non solo vehicle documents;
- produrre data inventory e privacy policy/disclosure per Open-Meteo, OpenRouteService, map/tile provider, Google ML Kit e altre chiamate/SDK;
- completare provenance/license ledger di package, asset, guide, provider e donor; distinguere COPY / ADAPT / IDEA ONLY;
- verificare ToS/licenze per uso offline, caching, attribution e distribuzione dei contenuti;
- decidere se e quando aggiungere Google Sign-In/backup cloud opzionale: mai rendere account o cloud requisito per il core local-first;
- nessun secret, key, service account o materiale personale deve entrare nel repo pubblico o negli artifact/log;
- aggiungere audit dei file non-code pubblici e della history prima della release.

Criterio di uscita:

- ogni boundary locale/rete/cloud/store ha ownership, minacce, dati inviati, licenza e recovery documentati.

## STEP 16P — Performance, memoria, batteria e stress

Stato: `TODO`

Problemi da risolvere tutti:

- usare AppLab come harness principale per persistence/restart, network-offline, storage/data-integrity, resource-pressure/process-death e performance; non duplicare i suoi runner dentro CamperBoss;
- benchmark cold/warm start, jank/FPS MapLibre, memoria, CPU e battery impact su device medio e alto;
- stress backup/restore con molti record e allegati grandi, OCR multipagina e photo export;
- stress GPX con molte migliaia di punti e Memories con molte foto;
- stress ricerca/index rebuild su dataset ampio e guide/manuali estesi;
- misurare MapLibre offline durante download/riapertura, low-memory/process death e storage quasi pieno;
- mantenere APK/IPA/Web size budget con breakdown delle dipendenze e regressione per release;
- non introdurre AI finché questa baseline non è misurata, perché servirà da controllo per RAM/battery/size del futuro STEP 17.

Criterio di uscita:

- Evidence Bundle con soglie, device di riferimento, risultati e regressioni ripetibili; baseline non-AI congelata per il confronto futuro con STEP 17.

## STEP 16Q — AppLab / device / Web certification finale

Stato: `TODO`

Gate obbligatori:

- eseguire i flow Maestro/AppLab preparati negli step precedenti sulla UI corrente; niente coordinate fragili, dati demo o assertion su testi non localizzati;
- Android release: first launch, locale, CRUD, document import/OCR, reminder permission, routing, backup/restore, MapLibre, process death e recovery;
- offline critical path: scarica regione, relaunch, rete disabilitata, riapri regione e usa zoom/pan senza rete;
- iPhone reale/simulatore compatibile: import documenti, OCR, notifiche, routing, lifecycle offline e privacy backup;
- Web/Pages sul commit canonico: navigazione, local persistence, locale, responsive desktop, refresh/back, graceful degradation native-only;
- permission denied/denied-forever, no network, provider quota/error, corrupt backup, low storage e retry;
- destructive flows e recovery: trip cascade, document references, Trash/Restore/Purge dove previsto;
- creare una sola release-candidate PR finale dal head STEP 16Q verso `main`, verificare che il diff comprenda l'intera catena 16D→16Q e chiudere come superseded le PR stacked intermedie solo dopo il confronto;
- eseguire CodeRabbit e tutti i required checks sulla PR finale verso `main`;
- dopo merge controllato, rilanciare certification su `main`, deployare Pages e verificare che SHA Web, release evidence, APK/AAB e artifact appartengano alla stessa baseline;
- evitare una full AppLab certification a ogni micro-commit: smoke mirati negli step 16L–16P, matrice completa soltanto qui;
- produrre verdetto finale `CERTIFIED` / `NOT CERTIFIED` / `BLOCKED` senza trasformare un build PASS in runtime PASS.

Criterio di uscita:

- STEP 16 può diventare `DONE` solo quando tutti i P0/P1 applicabili sono chiusi e i gate fisici sono dimostrati.

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
