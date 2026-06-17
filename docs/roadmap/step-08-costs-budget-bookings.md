# STEP 8 — Carburante, costi, budget e prenotazioni

## Obiettivo

Creare un dominio finanziario condiviso per:

- rifornimenti;
- consumo del mezzo;
- spese generiche;
- budget viaggio;
- prenotazioni;
- allegati;
- reminder.

Evitare tre sistemi separati per costi mezzo, viaggio e prenotazioni.

## Scope

Leggere soltanto:

- profilo mezzo;
- manutenzione;
- planner;
- documenti/allegati;
- promemoria locali;
- database Drift;
- dashboard coinvolte.

## Modelli suggeriti

```dart
enum ExpenseScope {
  vehicle,
  trip,
  maintenance,
}

enum ExpenseCategory {
  fuel,
  adBlue,
  toll,
  vignette,
  camping,
  parking,
  food,
  maintenance,
  ferry,
  activity,
  insurance,
  other,
}

class Expense {
  final String id;
  final ExpenseScope scope;
  final String? vehicleId;
  final String? tripId;
  final ExpenseCategory category;
  final int amountMinor;
  final String currencyCode;
  final DateTime occurredAt;
  final String? title;
  final String? notes;
  final String? documentId;
}
```

Usare importi in unità minori:

```text
12,34 EUR → 1234
```

Non usare `double` per il denaro.

## Rifornimenti

```dart
class FuelEntry {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometerKm;
  final int volumeMilliLitres;
  final int totalCostMinor;
  final String currencyCode;
  final bool fullTank;
  final String? station;
  final double? latitude;
  final double? longitude;
  final String? notes;
}
```

Calcolare:

* prezzo/litro;
* km fra pieni completi;
* consumo medio;
* costo/km;
* costo mensile;
* costo annuale.

Non calcolare consumi fra due rifornimenti non completi come se fossero dati affidabili.

## Budget viaggio

```dart
class TripBudget {
  final String tripId;
  final int plannedAmountMinor;
  final String currencyCode;
}

class BudgetSummary {
  final int plannedMinor;
  final int spentMinor;
  final int remainingMinor;
  final Map<ExpenseCategory, int> byCategory;
}
```

Mostrare:

* previsto;
* speso;
* residuo;
* costo/giorno;
* costo/km;
* categorie;
* andamento.

## Prenotazioni

Tipi minimi:

```dart
enum BookingType {
  campsite,
  camperArea,
  ferry,
  activity,
  restaurant,
  transport,
  insurance,
  vignette,
  other,
}
```

Campi:

```dart
class TripBooking {
  final String id;
  final String tripId;
  final BookingType type;
  final String title;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? address;
  final String? bookingCode;
  final int? costMinor;
  final String currencyCode;
  final String? contact;
  final String? notes;
  final String? documentId;
  final String? poiId;
}
```

Supportare:

* allegato documento;
* collegamento a POI;
* aggiunta al budget;
* reminder;
* apertura navigazione;
* stato confermato/annullato/completato.

## Valute

Prima versione:

* una valuta principale per viaggio;
* nessuna conversione automatica inventata;
* eventuale cambio inserito esplicitamente;
* mantenere valore originale e valuta originale.

## Dashboard

Mezzo:

* consumo medio;
* costo carburante;
* costo manutenzione;
* costo/km.

Viaggio:

* budget;
* speso;
* prenotazioni future;
* categorie principali.

## Test

* calcolo importi;
* prezzo/litro;
* consumo fra pieni;
* rifornimento parziale;
* costo/km;
* budget residuo;
* categorie;
* valuta;
* booking CRUD;
* allegato;
* reminder;
* migrazione Drift;
* provider;
* widget riepilogo.

## Criteri di completamento

* dati persistenti;
* calcoli deterministici;
* nessun errore di arrotondamento monetario;
* rifornimenti collegati al mezzo;
* spese collegate a mezzo o viaggio;
* prenotazioni collegate al planner;
* reminder e allegati riusano i servizi esistenti.

## Commit

`feat(finance): add fuel expenses trip budgets and bookings`
