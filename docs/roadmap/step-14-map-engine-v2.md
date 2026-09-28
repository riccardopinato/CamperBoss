# Step 14 — Map Engine V2 + offline reale

## Stato

Implementation POC: in verifica.
Roadmap: CURRENT fino a validazione runtime offline su device.

## Obiettivo

Sostituire in modo controllato il limite del primo tentativo PMTiles con un
renderer vettoriale MapLibre capace di:

- mantenere la mappa attuale funzionante durante la migrazione;
- renderizzare POI reali e filtri esistenti;
- raggruppare POI in cluster senza legare il dominio al renderer;
- preparare regioni cartografiche native offline su Android e iOS;
- compilare anche sul Web, dove il POC resta online;
- non dichiarare una regione "offline pronta" senza conferma del motore nativo.

## Strategia di migrazione

Il renderer esistente basato su flutter_map resta la mappa primaria durante
questo step. Map Engine V2 vive in una schermata di preview isolata e riceve gli
stessi POI filtrati della mappa corrente.

La sostituzione del renderer principale è ammessa soltanto dopo:

1. build Android, iOS e Web riuscite;
2. rendering vettoriale reale verificato;
3. POI e cluster verificati;
4. download regione offline completato su Android/iOS;
5. riapertura della regione senza rete verificata;
6. nessuna regressione della mappa esistente.

## Architettura

### MapLibre configuration

`MapEngineV2Config` centralizza engine id, stile OpenFreeMap, attribution e
politica di zoom offline.

### POI clustering

`MapLibrePoiClusterer` è puro Dart. Riceve i `CamperPlace` già filtrati e
restituisce gruppi geografici dipendenti dallo zoom. La logica non dipende da
MapLibre e rimane sostituibile/testabile.

### Renderer POC

`MapEngineV2PreviewScreen`:

- usa MapLibre vector rendering;
- usa annotazioni circle per POI e cluster;
- ricalcola i cluster quando la camera si ferma;
- seleziona un POI singolo;
- ingrandisce la mappa quando viene toccato un cluster;
- mantiene il callback Directions esistente.

### Offline native regions

`MapLibreOfflineRegionManager` separa il contratto dal binding MapLibre.

`NativeMapLibreOfflineRegionManager` usa le regioni offline native su Android
e iOS. Il Web non espone falsi stati offline.

Il download parte dall'area visibile e usa zoom massimi adattivi per limitare
consumo dati e storage. Le regioni CamperBoss sono identificate tramite metadata
propri e non vengono confuse con regioni create da altre app/logiche.

## Relazione con Step 7

Lo Step 7 rimane traccia storica del tentativo PMTiles. Il suo stato BLOCKED non
viene cancellato retroattivamente. Quando Map Engine V2 supera la validazione
runtime offline, lo Step 14 assorbe definitivamente quel requisito.

## Verifica automatica

- `flutter analyze`
- `flutter test`
- test clustering MapLibre
- test normalizzazione bounds/zoom offline
- widget test preview senza platform view
- build Android ARM64 debug
- build Web release
- build iOS simulator

## Verifica runtime obbligatoria prima di DONE

### Android / iOS

1. Aprire Mappa > Map Engine V2 > Preview.
2. Verificare caricamento stile vettoriale.
3. Verificare POI e cluster.
4. Muovere/zoomare e verificare ricalcolo cluster.
5. Toccare un cluster e verificare zoom.
6. Toccare un POI e verificare dettagli/directions.
7. Usare "Offline this area".
8. Attendere completamento download.
9. Chiudere e riaprire l'app.
10. Disabilitare rete.
11. Riaprire la stessa area e verificare che la cartografia preparata resti
    disponibile.

### Web

1. Verificare rendering vettoriale.
2. Verificare POI, cluster e interazioni.
3. Confermare che il download nativo offline non venga presentato come
   disponibile.

## Gate

Lo step resta CURRENT finché la prova runtime offline non è documentata.
Compilare correttamente non equivale a dimostrare l'uso offline reale.
