# AGENTS.md

## Efficienza operativa e roadmap

- `ROADMAP.md` e l'unica fonte ufficiale del piano di sviluppo.
- Il comando `Prossimo step.` significa: leggi `AGENTS.md`, poi leggi esclusivamente lo step `CURRENT` in `ROADMAP.md` ed esegui solo quello.
- Se non esiste uno step `CURRENT` ma esistono step `TODO`, promuovi a `CURRENT` quello con priorita piu alta ed eseguilo.
- Se non esistono step `CURRENT` o `TODO`, comunica che la roadmap corrente e completata e non modificare codice.
- Lavora sempre su un solo step alla volta e solo sullo step `CURRENT`; non eseguire altri step nello stesso task.
- Non ripianificare gli altri step salvo richiesta esplicita.
- Parti soltanto dai file e dalle cartelle elencati nello scope dello step corrente.
- Leggi esclusivamente le dipendenze dirette necessarie per completare o compilare lo step.
- Non analizzare l'intero repository, non fare audit globali, refactoring generali o modifiche estranee.
- Ignora sempre `build/`, `.dart_tool/`, `ios/Pods/`, file generati, binari, ZIP, PDF, vecchi dossier, trascrizioni e documentazione non pertinente.
- Non aggiornare dipendenze non necessarie e non correggere warning o problemi preesistenti estranei allo step.
- Riutilizza architettura, servizi, provider e widget esistenti; non introdurre una seconda soluzione se ne esiste gia una funzionante.
- Se servono dipendenze dirette puoi aprirle; se serve coinvolgere un'altra feature o cartella principale fuori scope, fermati e chiedi autorizzazione.
- Esegui esclusivamente test pertinenti allo step e formatta soltanto i file modificati.
- Crea un singolo commit per ogni step.
- Se lo step e completato, aggiorna `ROADMAP.md` in-place: stato da `CURRENT` a `DONE`, risultato/test/commit in massimo tre righe, poi promuovi automaticamente il primo step successivo `TODO` a `CURRENT` senza implementarlo.
- Se lo step non puo essere completato, impostalo `BLOCKED`, annota sinteticamente il motivo, non promuovere altri step e chiedi come procedere.
- Mantieni sempre un solo step `CURRENT`; la promozione automatica non autorizza l'implementazione dello step successivo nello stesso task.
- Mantieni il riepilogo finale molto breve.
- Priorita permanente: minimizzare letture, tool call, output e consumo di token senza compromettere la correttezza.
