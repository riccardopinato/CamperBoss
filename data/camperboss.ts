export type Severity = "safe" | "watch" | "urgent";

export const bossScore = {
  level: 18,
  xp: 1840,
  next: 2200,
  badge: "Mastro di Bordo",
  streak: 9
};

export type CamperProfile = {
  nickname: string;
  brand: string;
  model: string;
  year: string;
  heightCm: number;
  maxWeightKg: number;
  currentWeightKg: number;
  waterLiters: number;
  batteryAh: number;
  solarWatts: number;
  gasBottles: number;
  people: number;
  petOnBoard: boolean;
};

export const defaultCamperProfile: CamperProfile = {
  nickname: "Boss Van",
  brand: "Laika",
  model: "Ecocamper",
  year: "2021",
  heightCm: 295,
  maxWeightKg: 3500,
  currentWeightKg: 3180,
  waterLiters: 110,
  batteryAh: 200,
  solarWatts: 280,
  gasBottles: 1,
  people: 2,
  petOnBoard: true
};

export const storageKeys = {
  camperProfile: "camperboss.camperProfile",
  checklist: "camperboss.checklist",
  expenses: "camperboss.expenses",
  serviceLogs: "camperboss.serviceLogs",
  trips: "camperboss.trips",
  diagnosisLogs: "camperboss.diagnosisLogs"
};

export type ExpenseEntry = {
  id: string;
  title: string;
  category: string;
  amount: number;
  date: string;
};

export type ServiceLogEntry = {
  id: string;
  title: string;
  due: string;
  progress: number;
  status: Severity;
  cost: number;
  note: string;
  date: string;
};

export type TripEntry = {
  id: string;
  place: string;
  km: number;
  mood: string;
  cost: number;
  date: string;
};

export type DiagnosisLogEntry = {
  id: string;
  title: string;
  category: string;
  answers: string[];
  kit: string;
  xp: number;
  date: string;
};

export const defaultExpenses: ExpenseEntry[] = [
  { id: "exp-fuel", title: "Gasolio Brennero", category: "Carburante", amount: 94, date: "2026-06-01" },
  { id: "exp-area", title: "Area sosta Ledro", category: "Sosta", amount: 24, date: "2026-06-02" },
  { id: "exp-service", title: "Scarico e acqua", category: "Servizi", amount: 8, date: "2026-06-03" }
];

export const defaultServiceLogs: ServiceLogEntry[] = [
  { id: "svc-water", title: "Sanificazione acque chiare", due: "tra 12 giorni", progress: 78, status: "watch", cost: 18, note: "Pastiglie e risciacquo completo.", date: "2026-05-22" },
  { id: "svc-roof", title: "Controllo sigillature tetto", due: "settembre 2026", progress: 44, status: "safe", cost: 0, note: "Nessuna crepa visibile.", date: "2026-04-14" },
  { id: "svc-gas", title: "Revisione impianto gas", due: "scade tra 31 giorni", progress: 91, status: "urgent", cost: 0, note: "Prenotare controllo regolatore.", date: "2026-05-30" },
  { id: "svc-dot", title: "DOT pneumatici", due: "anteriore 2021", progress: 64, status: "watch", cost: 0, note: "Valutare sostituzione prima dell'inverno.", date: "2026-03-18" }
];

export const cockpitStats = [
  { label: "Autonomia acqua", value: "2.8 gg", status: "watch" as Severity },
  { label: "Energia servizi", value: "68%", status: "safe" as Severity },
  { label: "Gas stimato", value: "4.5 gg", status: "safe" as Severity },
  { label: "Budget viaggio", value: "312 EUR", status: "watch" as Severity }
];

export const tMinusChecklist = [
  { id: "gas", title: "Valvole gas chiuse", detail: "Bombola, boiler, piano cottura e frigo in assetto marcia.", done: false, critical: true },
  { id: "roof", title: "Oblo e finestre bloccati", detail: "Controllo fisico piu foto mentale: tetto, bagno, mansarda.", done: false, critical: true },
  { id: "shore", title: "Cavo 230V scollegato", detail: "Cavo raccolto, sportello chiuso, adattatori in garage.", done: true, critical: true },
  { id: "step", title: "Gradino e piedini rientrati", detail: "Nessun appoggio meccanico resta esposto.", done: false, critical: true },
  { id: "cargo", title: "Garage e portabici serrati", detail: "Carico stabile, pesi bassi, serrature controllate.", done: true, critical: false },
  { id: "water", title: "Acque e WC verificati", detail: "Chiare sufficienti, grigie chiuse, cassetta pronta.", done: false, critical: false }
];

export const diagnosisCategories = [
  {
    id: "gas",
    title: "Gas e clima",
    subtitle: "Frigo, stufa, boiler, FrostControl",
    accent: "#C95F4A",
    cases: [
      {
        title: "Frigo trivalente non parte a gas",
        steps: [
          "I fornelli si accendono? Se no, verifica bombola, riduttore e valvola principale.",
          "Senti il ticchettio del piezo? Se no, controlla fusibile e 12V servizi.",
          "Il camper e in bolla? I frigo ad assorbimento soffrono le pendenze.",
          "Se arriva gas e scintilla, pulisci griglia esterna e ugello bruciatore con aria delicata."
        ],
        kit: "Kit aria compressa, spazzolino morbido, guanti, torcia frontale",
        xp: 50
      },
      {
        title: "Stufa in errore all'accensione",
        steps: [
          "Controlla che scarico e presa aria esterna siano liberi.",
          "Verifica tensione batteria: sotto carico alcune stufe vanno in protezione.",
          "Fai reset completo, attendi due minuti, poi riavvia con temperatura alta.",
          "Se l'errore torna, registra codice LED e crea ticket officina."
        ],
        kit: "Multimetro, manuale stufa, foto del codice errore",
        xp: 45
      }
    ]
  },
  {
    id: "water",
    title: "Acqua",
    subtitle: "Pompa, perdite, serbatoi, odori",
    accent: "#1E6B7A",
    cases: [
      {
        title: "Pompa che pulsa a vuoto",
        steps: [
          "Controlla livello acque chiare e pescante.",
          "Apri un rubinetto alla volta per spurgare aria dal circuito.",
          "Ispeziona giunti sotto lavello, bagno e boiler con carta assorbente.",
          "Se la pompa riparte da sola ogni minuto, cerca microperdite o pressostato starato."
        ],
        kit: "Carta assorbente, fascette, raccordi rapidi, chiave piccola",
        xp: 40
      }
    ]
  },
  {
    id: "energy",
    title: "Energia",
    subtitle: "Batterie, inverter, pannelli, 230V",
    accent: "#D99A3D",
    cases: [
      {
        title: "Inverter in blocco",
        steps: [
          "Spegni carichi energivori e attendi il raffreddamento.",
          "Verifica watt richiesti e picco di avvio dell'elettrodomestico.",
          "Misura tensione batteria sotto carico.",
          "Riaccendi con un solo carico e salva l'assorbimento nel diario."
        ],
        kit: "Multimetro, pinza amperometrica, tabella carichi",
        xp: 35
      }
    ]
  },
  {
    id: "cell",
    title: "Cellula",
    subtitle: "Oblo, infiltrazioni, rumori, assetto",
    accent: "#2F6B4F",
    cases: [
      {
        title: "Infiltrazione improvvisa",
        steps: [
          "Asciuga subito e fotografa il punto di ingresso.",
          "Riduci la pressione dell'acqua con telo o nastro provvisorio esterno.",
          "Non sigillare su bagnato se puoi evitarlo: serve una riparazione temporanea pulita.",
          "Programma controllo professionale entro pochi giorni."
        ],
        kit: "Panno, nastro butilico, telo, deumidificatore compatto",
        xp: 60
      }
    ]
  }
];

export const serviceItems = [
  { title: "Sanificazione acque chiare", due: "tra 12 giorni", progress: 78, status: "watch" as Severity },
  { title: "Controllo sigillature tetto", due: "settembre 2026", progress: 44, status: "safe" as Severity },
  { title: "Revisione impianto gas", due: "scade tra 31 giorni", progress: 91, status: "urgent" as Severity },
  { title: "DOT pneumatici", due: "anteriore 2021", progress: 64, status: "watch" as Severity }
];

export const hacks = [
  { title: "Frigo estivo piu efficiente", body: "Parcheggia con griglie in ombra, puliscile e lascia circolare aria: rende piu di molti accessori comprati al volo.", tag: "Estate" },
  { title: "Manuale del mio camper", body: "Ogni problema risolto diventa una scheda: sintomo, test, pezzo usato, foto e costo. E il libretto service cresce da solo.", tag: "Valore" },
  { title: "Off-grid senza ansia", body: "Calcola consumo reale della sera prima di accendere inverter e stufa insieme. Il Boss Score premia le notti autosufficienti.", tag: "Autonomia" }
];

export const petTasks = [
  "Passaporto UE e antirabbica controllati",
  "Ciotola pieghevole, farmaci e guinzaglio di scorta",
  "Temperatura cellula sotto soglia sicurezza",
  "Area sosta verificata dog-friendly"
];

export const tripLog = [
  { place: "Lago di Ledro", km: 186, mood: "Sosta libera ordinata", cost: 42 },
  { place: "Val di Funes", km: 94, mood: "Notte fredda, gas ok", cost: 28 },
  { place: "Ferrara", km: 211, mood: "Area comoda, scarico perfetto", cost: 61 }
];

export const defaultTrips: TripEntry[] = [
  { id: "trip-ledro", place: "Lago di Ledro", km: 186, mood: "Sosta libera ordinata", cost: 42, date: "2026-06-01" },
  { id: "trip-funes", place: "Val di Funes", km: 94, mood: "Notte fredda, gas ok", cost: 28, date: "2026-06-02" },
  { id: "trip-ferrara", place: "Ferrara", km: 211, mood: "Area comoda, scarico perfetto", cost: 61, date: "2026-06-03" }
];

export const defaultDiagnosisLogs: DiagnosisLogEntry[] = [];
