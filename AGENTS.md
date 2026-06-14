# AGENTS.md

## Efficienza operativa e roadmap

- `ROADMAP.md` e l'unica fonte ufficiale del piano.
- Lavora su un solo step `CURRENT` alla volta.
- Leggi solo lo step corrente, i file nel suo scope e le dipendenze dirette indispensabili.
- Non analizzare l'intero repository, non fare audit o refactoring globali e non correggere problemi estranei.
- Ignora `build/`, `.dart_tool/`, `ios/Pods/`, file generati, ZIP, PDF e documentazione non pertinente.
- Tutti i controlli visibili devono funzionare realmente; nascondi o disabilita chiaramente quelli non implementati.
- Ogni dato inserito deve essere realmente salvato e la UI deve aggiornarsi dopo il CRUD.
- Nessun errore deve essere ignorato o trasformato silenziosamente in lista vuota.
- La persistenza deve funzionare localmente, offline, su mobile e web, anche senza login.
- Usa database, repository e provider condivisi; non creare database direttamente nelle schermate.
- I documenti personali restano locali e privati salvo consenso esplicito al cloud.
- Non chiamare "mappa offline" una semplice cache di POI.
- Esegui test mirati, formatta solo i file modificati e crea un commit per step.
- Priorita: correttezza con il minimo consumo possibile di token, letture e tool call.

## Gestione automatica

Quando ricevi `Procedi con il prossimo step.`:

1. esegui solo lo step `CURRENT`;
2. se completato, impostalo `DONE`;
3. registra risultato, test e commit in massimo 3 righe;
4. promuovi il primo `TODO` a `CURRENT`, senza eseguirlo;
5. fermati.

Se fallisce, impostalo `BLOCKED`, annota il motivo e non promuovere altri step.
