# AGENTS.md

## Roadmap tecnica modulare

- `ROADMAP.md` contiene stato e riferimento alla specifica di ogni step.
- Per ogni task leggere solo `AGENTS.md`, `ROADMAP.md` e il file `Spec` dello step `CURRENT`.
- Non leggere i file di specifica degli step futuri.
- Leggere solo i file di codice nello scope dello step corrente e le dipendenze dirette indispensabili.
- Non analizzare l'intero repository, non fare audit o refactoring globali e non correggere problemi estranei.
- Ignora `build/`, `.dart_tool/`, `ios/Pods/`, file generati, ZIP, PDF e documentazione non pertinente.
- Se serve una feature fuori scope, fermati e motivane la necessità.
- Non copiare moduli esterni; reimplementa in Dart i pattern necessari e conserva attribuzioni e licenze quando porti codice sostanziale.
- Un task completa un solo step, produce un solo commit e si ferma.
- Aggiorna `ROADMAP.md` in-place senza cronologie estese.
- Priorità permanente: correttezza, testabilità e minimo consumo di token, letture e tool call.

## Gestione automatica

Quando ricevi `Procedi con il prossimo step.`:

1. esegui solo lo step `CURRENT`;
2. se completato, impostalo `DONE`;
3. registra risultato, test e commit in massimo 3 righe;
4. promuovi il primo `TODO` a `CURRENT`, senza eseguirlo;
5. fermati.

Se fallisce, impostalo `BLOCKED`, annota il motivo e non promuovere altri step.
