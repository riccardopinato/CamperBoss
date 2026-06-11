# CamperBoss

CamperBoss e un sistema operativo mobile per camperisti: cockpit di partenza, diagnostica rapida, planner autonomia, diario service, budget, pet companion e diario di bordo.

## Moduli MVP

- Cockpit: Boss Score, risorse critiche, checklist T-Minus e hack tecnici.
- SOS Diagnostica: flussi guidati per gas, acqua, energia e cellula.
- Planner: autonomia acqua, batteria, gas, carico utile, budget e pet.
- Garage: diario service digitale per manutenzione e valore di rivendita.
- Diario: tappe, costi, chilometri e memoria operativa del viaggio.
- Profilo camper: dati mezzo persistenti per personalizzare calcoli e checklist.
- Redesign Explorer: dark slate UI, accenti neon, icone Lucide, mini mappa visuale, SOS wizard a domande e card tecniche.
- Bento UI: cockpit e planner organizzati in blocchi arrotondati, con colori pastello decisi e micro-interazioni elastiche via Reanimated.
- Temi: modalita chiara, scura e automatica sincronizzata con il sistema, selezionabile dal Profilo.

## Avvio

```bash
npm install
npm run web
```

Poi apri `http://localhost:19006`.

## Verifica eseguita

- `npm run typecheck`
- Bundle Expo web completato su `http://localhost:19006`
- `Invoke-WebRequest` su `http://localhost:19006` con risposta HTTP 200
- Redesign verificato con bundle Metro pulito dopo installazione di `lucide-react-native`, `expo-linear-gradient`, `expo-blur` e `react-native-svg`.

Nota: `npm audit` segnala vulnerabilita moderate nella catena Expo/xcode/uuid. Il fix automatico suggerito usa `--force` e installerebbe una versione Expo incompatibile, quindi va evitato finche Expo non rilascia un aggiornamento coerente con SDK 55.
