# Step 15 — Routing camper-aware

## Stato

CURRENT fino a CI verde.

## Obiettivo

Usare il profilo mezzo già salvato per adattare il routing quando il provider
supporta restrizioni dimensionali, senza dichiarare il percorso sicuro o
garantito.

## Implementazione

- `CamperRoutingProfileResolver` traduce il profilo mezzo in un
  `RouteRequest`.
- Con profilo mezzo valido usa OpenRouteService `driving-hgv`.
- Invia:
  - lunghezza in metri;
  - larghezza in metri;
  - altezza in metri;
  - massa massima in tonnellate.
- Imposta `vehicle_type: hgv`, richiesto da ORS per applicare le restrizioni
  heavy-vehicle.
- Senza profilo valido mantiene `driving-car`.
- Le dimensioni fanno parte del fingerprint della route: modificare il camper
  rende automaticamente obsoleta la route salvata precedente.
- La UI indica chiaramente se il routing camper-aware è attivo e mostra i valori
  realmente inviati al provider.
- Il warning sulla non garanzia di transitabilità resta sempre visibile.

## Sicurezza e limiti

Il routing dipende dalla qualità e completezza dei dati OSM/provider. CamperBoss
non deve presentare il risultato come certificazione della strada.

Non vengono inviati targa, marca, modello, note, posizione storica o altri dati
del profilo non necessari al calcolo.

## Test

- fallback driving-car senza profilo;
- mapping dimensioni/massa;
- conversione kg -> tonnellate;
- fingerprint cambia con le dimensioni;
- payload ORS contiene le restrizioni solo per driving-hgv;
- suite Flutter completa e analyze.
