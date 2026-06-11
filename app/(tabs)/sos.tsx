import { useMemo, useState } from "react";
import { BatteryCharging, CheckCircle2, Droplets, Flame, Home, RotateCcw, ShieldAlert, Siren, Wrench } from "lucide-react-native";
import { ScrollView, Text, View } from "react-native";
import { today } from "@/components/form";
import { Card, ElasticPressable, NeonButton, Pill, ProgressBar, ScreenShell, SectionTitle } from "@/components/ui";
import { colors } from "@/constants/theme";
import { defaultDiagnosisLogs, diagnosisCategories, storageKeys, type DiagnosisLogEntry } from "@/data/camperboss";
import { useStorage } from "@/hooks/use-storage";

const iconByCategory = {
  gas: Flame,
  water: Droplets,
  energy: BatteryCharging,
  cell: Home
};

export default function SosScreen() {
  const [diagnosisLogs, setDiagnosisLogs] = useStorage<DiagnosisLogEntry[]>(storageKeys.diagnosisLogs, defaultDiagnosisLogs);
  const [categoryId, setCategoryId] = useState(diagnosisCategories[0].id);
  const [caseIndex, setCaseIndex] = useState(0);
  const [stepIndex, setStepIndex] = useState(0);
  const [answered, setAnswered] = useState<string[]>([]);
  const category = useMemo(() => diagnosisCategories.find((item) => item.id === categoryId) ?? diagnosisCategories[0], [categoryId]);
  const activeCase = category.cases[Math.min(caseIndex, category.cases.length - 1)];
  const progress = ((stepIndex + 1) / activeCase.steps.length) * 100;
  const finished = stepIndex >= activeCase.steps.length - 1 && answered.length >= activeCase.steps.length;
  const CurrentIcon = iconByCategory[category.id as keyof typeof iconByCategory] ?? Wrench;

  const choose = (answer: string) => {
    const nextAnswers = [...answered.slice(0, stepIndex), answer];
    setAnswered(nextAnswers);
    if (stepIndex < activeCase.steps.length - 1) {
      setStepIndex(stepIndex + 1);
    }
  };

  const resetFlow = () => {
    setStepIndex(0);
    setAnswered([]);
  };

  const saveDiagnosis = () => {
    const entry: DiagnosisLogEntry = {
      id: `diagnosis-${Date.now()}`,
      title: activeCase.title,
      category: category.title,
      answers: answered,
      kit: activeCase.kit,
      xp: activeCase.xp,
      date: today()
    };
    setDiagnosisLogs([entry, ...diagnosisLogs]);
    resetFlow();
  };

  return (
    <ScreenShell>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ gap: 18, padding: 18, paddingBottom: 34 }}>
        <Card tint="rgba(59, 23, 28, 0.82)" accent={colors.red}>
          <View style={{ gap: 14 }}>
            <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 12 }}>
              <Pill label="SOS anti-panico" tone={colors.redSoft} color={colors.red} />
              <Siren color={colors.red} size={30} strokeWidth={2.8} />
            </View>
            <Text selectable style={{ color: colors.text, fontSize: 30, fontWeight: "900" }}>Diagnostica guidata da strada.</Text>
            <Text selectable style={{ color: colors.textSoft, fontSize: 15, lineHeight: 22 }}>
              Poche domande, niente panico: isola il sintomo, controlla il kit e salva la soluzione nel service.
            </Text>
          </View>
        </Card>

        <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
          {diagnosisCategories.map((item) => {
            const Icon = iconByCategory[item.id as keyof typeof iconByCategory] ?? Wrench;
            const active = item.id === categoryId;
            return (
              <ElasticPressable
                key={item.id}
                onPress={() => {
                  setCategoryId(item.id);
                  setCaseIndex(0);
                  resetFlow();
                }}
                scaleTo={0.965}
                style={{
                  backgroundColor: active ? `${item.accent}33` : "rgba(255,255,255,0.04)",
                  borderColor: active ? item.accent : colors.line,
                  borderRadius: 16,
                  borderWidth: 1,
                  flexBasis: "48%",
                  flexGrow: 1,
                  gap: 10,
                  minHeight: 116,
                  padding: 14
                }}
              >
                <Icon color={active ? item.accent : colors.textSoft} size={24} strokeWidth={2.4} />
                <View style={{ gap: 5 }}>
                  <Text selectable style={{ color: colors.text, fontSize: 17, fontWeight: "900" }}>{item.title}</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 12, lineHeight: 17 }}>{item.subtitle}</Text>
                </View>
              </ElasticPressable>
            );
          })}
        </View>

        <SectionTitle kicker="Wizard tecnico" title={activeCase.title} action={`+${activeCase.xp} XP`} />
        <Card tint="rgba(13, 27, 34, 0.90)" accent={category.accent}>
          <View style={{ gap: 16 }}>
            <View style={{ alignItems: "center", flexDirection: "row", gap: 12 }}>
              <View style={{ alignItems: "center", backgroundColor: `${category.accent}22`, borderRadius: 999, height: 48, justifyContent: "center", width: 48 }}>
                <CurrentIcon color={category.accent} size={25} strokeWidth={2.7} />
              </View>
              <View style={{ flex: 1, gap: 6 }}>
                <Text selectable style={{ color: colors.textSoft, fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>
                  Step {stepIndex + 1} di {activeCase.steps.length}
                </Text>
                <ProgressBar value={progress} color={category.accent} />
              </View>
            </View>

            <View style={{ backgroundColor: "rgba(255,255,255,0.05)", borderColor: colors.line, borderRadius: 16, borderWidth: 1, gap: 10, padding: 16 }}>
              <ShieldAlert color={colors.neon} size={24} strokeWidth={2.5} />
              <Text selectable style={{ color: colors.text, fontSize: 21, fontWeight: "900", lineHeight: 27 }}>{activeCase.steps[stepIndex]}</Text>
              <Text selectable style={{ color: colors.textSoft, fontSize: 13, lineHeight: 19 }}>
                Rispondi in base a quello che vedi o senti sul mezzo. CamperBoss costruisce il log tecnico della diagnosi.
              </Text>
            </View>

            <View style={{ flexDirection: "row", gap: 10 }}>
              <ElasticPressable onPress={() => choose("no")} scaleTo={0.94} style={{ backgroundColor: colors.panelSoft, borderColor: colors.lineStrong, borderRadius: 14, borderWidth: 1, flex: 1, padding: 14 }}>
                <Text selectable style={{ color: colors.text, fontSize: 16, fontWeight: "900", textAlign: "center" }}>No</Text>
              </ElasticPressable>
              <ElasticPressable onPress={() => choose("yes")} scaleTo={0.94} style={{ backgroundColor: colors.cyanSoft, borderColor: colors.cyan, borderRadius: 14, borderWidth: 1, flex: 1, padding: 14 }}>
                <Text selectable style={{ color: colors.cyan, fontSize: 16, fontWeight: "900", textAlign: "center" }}>Si</Text>
              </ElasticPressable>
            </View>

            {finished ? (
              <View style={{ backgroundColor: colors.greenSoft, borderColor: colors.green, borderRadius: 16, borderWidth: 1, gap: 10, padding: 14 }}>
                <View style={{ gap: 10 }}>
                  <CheckCircle2 color={colors.green} size={26} strokeWidth={2.6} />
                  <Text selectable style={{ color: colors.text, fontSize: 20, fontWeight: "900" }}>Diagnosi completata</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 14, lineHeight: 20 }}>
                    Salva nel diario service: sintomo, controlli effettuati, kit usato e XP guadagnati.
                  </Text>
                  <NeonButton label="Salva soluzione nel service" icon={CheckCircle2} onPress={saveDiagnosis} />
                </View>
              </View>
            ) : null}

            <View style={{ backgroundColor: colors.yellowSoft, borderColor: "rgba(255,209,102,0.30)", borderRadius: 14, borderWidth: 1, gap: 6, padding: 12 }}>
              <Text selectable style={{ color: colors.yellow, fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>Kit consigliato</Text>
              <Text selectable style={{ color: colors.text, fontSize: 14, lineHeight: 20 }}>{activeCase.kit}</Text>
            </View>

            <ElasticPressable onPress={resetFlow} scaleTo={0.96} style={{ alignItems: "center", flexDirection: "row", gap: 8, justifyContent: "center", padding: 10 }}>
              <RotateCcw color={colors.textSoft} size={16} strokeWidth={2.4} />
              <Text selectable style={{ color: colors.textSoft, fontSize: 13, fontWeight: "900" }}>Ricomincia flusso</Text>
            </ElasticPressable>
          </View>
        </Card>

        {category.cases.length > 1 ? (
          <View style={{ flexDirection: "row", gap: 10 }}>
            {category.cases.map((item, index) => (
              <ElasticPressable
                key={item.title}
                onPress={() => {
                  setCaseIndex(index);
                  resetFlow();
                }}
                style={{ flex: 1 }}
              >
                <Card tint={index === caseIndex ? `${category.accent}22` : colors.panelSolid} accent={index === caseIndex ? category.accent : undefined}>
                  <Text selectable style={{ color: colors.text, fontSize: 13, fontWeight: "900" }}>{item.title}</Text>
                </Card>
              </ElasticPressable>
            ))}
          </View>
        ) : null}
        {diagnosisLogs.length > 0 ? (
          <>
            <SectionTitle kicker="Service log" title="Diagnosi salvate" action={`${diagnosisLogs.length}`} />
            {diagnosisLogs.slice(0, 3).map((item) => (
              <Card key={item.id} tint={colors.panelSolid} accent={colors.green}>
                <View style={{ gap: 6 }}>
                  <Text selectable style={{ color: colors.text, fontSize: 16, fontWeight: "900" }}>{item.title}</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 13 }}>{item.category} - {item.date} - +{item.xp} XP</Text>
                </View>
              </Card>
            ))}
          </>
        ) : null}
      </ScrollView>
    </ScreenShell>
  );
}
