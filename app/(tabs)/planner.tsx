import { BatteryCharging, Dog, Droplets, Flame, Plus, Scale, WalletCards } from "lucide-react-native";
import { useState } from "react";
import { ScrollView, Text, View } from "react-native";
import { FormField, FormModal, today, toNumber } from "@/components/form";
import { BentoTile, Card, MapPreview, NeonButton, Pill, ProgressBar, ScreenShell, SectionTitle } from "@/components/ui";
import { colors } from "@/constants/theme";
import { defaultCamperProfile, defaultExpenses, petTasks, storageKeys, type CamperProfile, type ExpenseEntry } from "@/data/camperboss";
import { useStorage } from "@/hooks/use-storage";

export default function PlannerScreen() {
  const [profile] = useStorage<CamperProfile>(storageKeys.camperProfile, defaultCamperProfile);
  const [expenses, setExpenses] = useStorage<ExpenseEntry[]>(storageKeys.expenses, defaultExpenses);
  const [expenseModalOpen, setExpenseModalOpen] = useState(false);
  const [expenseDraft, setExpenseDraft] = useState({ title: "", category: "Viaggio", amount: "" });
  const people = Math.max(1, profile.people);
  const waterDays = profile.waterLiters / (people * 18);
  const batteryScore = Math.min(96, 42 + profile.batteryAh / 5 + profile.solarWatts / 18);
  const gasDays = profile.gasBottles * (profile.petOnBoard ? 3.8 : 4.5);
  const weightPercent = profile.maxWeightKg > 0 ? (profile.currentWeightKg / profile.maxWeightKg) * 100 : 0;
  const resources = [
    { label: "Acqua", value: `${waterDays.toFixed(1)} gg`, percent: Math.min(100, waterDays * 24), detail: `${profile.waterLiters} L, ${people} persone`, color: colors.cyan, icon: Droplets },
    { label: "Energia", value: `${Math.round(batteryScore)}%`, percent: batteryScore, detail: `${profile.batteryAh}Ah + ${profile.solarWatts}W`, color: colors.green, icon: BatteryCharging },
    { label: "Gas", value: `${gasDays.toFixed(1)} gg`, percent: Math.min(100, gasDays * 18), detail: `${profile.gasBottles} bombole stimate`, color: colors.neon, icon: Flame },
    { label: "Peso", value: `${Math.round(weightPercent)}%`, percent: weightPercent, detail: `${Math.max(0, profile.maxWeightKg - profile.currentWeightKg)} kg margine`, color: weightPercent > 90 ? colors.red : colors.yellow, icon: Scale }
  ];
  const totalExpenses = expenses.reduce((sum, item) => sum + item.amount, 0);

  const addExpense = () => {
    const title = expenseDraft.title.trim() || "Spesa viaggio";
    const entry: ExpenseEntry = {
      id: `expense-${Date.now()}`,
      title,
      category: expenseDraft.category.trim() || "Viaggio",
      amount: toNumber(expenseDraft.amount, 0),
      date: today()
    };
    setExpenses([entry, ...expenses]);
    setExpenseDraft({ title: "", category: "Viaggio", amount: "" });
    setExpenseModalOpen(false);
  };

  return (
    <ScreenShell>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ gap: 18, padding: 18, paddingBottom: 34 }}>
        <SectionTitle kicker="Resource planner" title="Sosta libera, dati veri" />
        <MapPreview />

        <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
          {resources.map((item) => {
            const Icon = item.icon;
            const tint = item.color === colors.cyan ? colors.cyanSoft : item.color === colors.green ? colors.greenSoft : item.color === colors.neon ? colors.neonSoft : colors.yellowSoft;
            return (
              <BentoTile key={item.label} accent={item.color} tint={tint}>
                <View style={{ flex: 1, gap: 12, justifyContent: "space-between" }}>
                  <View style={{ alignItems: "center", flexDirection: "row", gap: 10, justifyContent: "space-between" }}>
                    <Text selectable style={{ color: colors.textSoft, flex: 1, fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>{item.label}</Text>
                    <View style={{ alignItems: "center", backgroundColor: "rgba(255,255,255,0.10)", borderRadius: 999, height: 34, justifyContent: "center", width: 34 }}>
                      <Icon color={item.color} size={18} strokeWidth={2.5} />
                    </View>
                  </View>
                  <View style={{ gap: 8 }}>
                    <Text selectable style={{ color: colors.text, fontSize: 24, fontWeight: "900" }}>{item.value}</Text>
                    <ProgressBar value={item.percent} color={item.color} />
                    <Text selectable style={{ color: colors.textSoft, fontSize: 12, lineHeight: 17 }}>{item.detail}</Text>
                  </View>
                </View>
              </BentoTile>
            );
          })}
        </View>

        <Card tint="rgba(255, 138, 42, 0.12)" accent={colors.neon}>
          <View style={{ gap: 14 }}>
            <View style={{ alignItems: "center", flexDirection: "row", gap: 12 }}>
              <WalletCards color={colors.neon} size={26} strokeWidth={2.5} />
              <View style={{ flex: 1, gap: 4 }}>
                <Pill label="Budget tracker" tone={colors.neonSoft} color={colors.neon} />
                <Text selectable style={{ color: colors.text, fontSize: 24, fontWeight: "900" }}>{totalExpenses.toFixed(0)} EUR registrati</Text>
              </View>
            </View>
            <Text selectable style={{ color: colors.textSoft, fontSize: 14, lineHeight: 20 }}>
              Inserisci carburante, pedaggi, area sosta, scarico e fondo emergenze. Le ultime spese restano salvate sul dispositivo.
            </Text>
            <View style={{ gap: 8 }}>
              {expenses.slice(0, 3).map((expense) => (
                <View key={expense.id} style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 10 }}>
                  <Text selectable style={{ color: colors.textSoft, flex: 1, fontSize: 13 }}>{expense.title}</Text>
                  <Text selectable style={{ color: colors.text, fontSize: 13, fontVariant: ["tabular-nums"], fontWeight: "900" }}>{expense.amount.toFixed(0)} EUR</Text>
                </View>
              ))}
            </View>
            <NeonButton label="Aggiungi spesa" icon={Plus} onPress={() => setExpenseModalOpen(true)} />
          </View>
        </Card>

        <SectionTitle kicker="Zampette a bordo" title="Pet companion operativo" />
        <Card tint="rgba(19, 51, 58, 0.70)" accent={colors.cyan}>
          <View style={{ gap: 12 }}>
            <View style={{ alignItems: "center", flexDirection: "row", gap: 10 }}>
              <Dog color={colors.cyan} size={24} strokeWidth={2.6} />
              <Text selectable style={{ color: colors.text, fontSize: 18, fontWeight: "900" }}>Checklist pet attiva</Text>
            </View>
            {petTasks.map((task, index) => (
              <View key={task} style={{ flexDirection: "row", gap: 10 }}>
                <Text selectable style={{ color: colors.cyan, fontWeight: "900" }}>{index + 1}</Text>
                <Text selectable style={{ color: colors.textSoft, flex: 1, fontSize: 15, lineHeight: 21 }}>{task}</Text>
              </View>
            ))}
          </View>
        </Card>
        <FormModal title="Nuova spesa" visible={expenseModalOpen} onClose={() => setExpenseModalOpen(false)} onSave={addExpense}>
          <FormField label="Descrizione" value={expenseDraft.title} onChangeText={(title) => setExpenseDraft({ ...expenseDraft, title })} />
          <FormField label="Categoria" value={expenseDraft.category} onChangeText={(category) => setExpenseDraft({ ...expenseDraft, category })} />
          <FormField label="Importo EUR" keyboardType="numeric" value={expenseDraft.amount} onChangeText={(amount) => setExpenseDraft({ ...expenseDraft, amount })} />
        </FormModal>
      </ScrollView>
    </ScreenShell>
  );
}
