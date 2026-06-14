# AGENTS.md

## Efficienza operativa e roadmap

- `ROADMAP.md` e l'unica fonte ufficiale del piano di sviluppo.
- Lavora sempre su un solo step alla volta e solo sullo step `CURRENT`.
- Prima di ogni intervento leggi esclusivamente lo step `CURRENT`.
- Non ripianificare gli altri step salvo richiesta esplicita.
- Parti soltanto dai file e dalle cartelle elencati nello scope dello step corrente.
- Leggi esclusivamente le dipendenze dirette necessarie per completare o compilare lo step.
- Non analizzare l'intero repository, non fare audit globali, refactoring generali o modifiche estranee.
- Ignora sempre `build/`, `.dart_tool/`, `ios/Pods/`, file generati, binari, ZIP, PDF, vecchi dossier, trascrizioni e documentazione non pertinente.
- Non aggiornare dipendenze non necessarie e non correggere warning o problemi preesistenti estranei allo step.
- Riutilizza architettura, servizi, provider e widget esistenti; non introdurre una seconda soluzione se ne esiste gia una funzionante.
- Se servono dipendenze dirette puoi aprirle; se serve coinvolgere un'altra feature o cartella principale fuori scope, fermati e chiedi autorizzazione.
- Esegui esclusivamente test pertinenti allo step e formatta soltanto i file modificati.
- Crea un singolo commit per ogni step, aggiorna `ROADMAP.md`, poi fermati e attendi conferma.
- Mantieni il riepilogo finale molto breve.
- Priorita permanente: minimizzare letture, tool call, output e consumo di token senza compromettere la correttezza.
