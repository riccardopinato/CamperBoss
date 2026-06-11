import { MonitorSmartphone, Moon, Ruler, Save, Settings2, Sun, UserRound, Weight } from "lucide-react-native";
import { ScrollView, Switch, Text, TextInput, View } from "react-native";
import { Card, ElasticPressable, Pill, ProgressBar, ScreenShell, SectionTitle } from "@/components/ui";
import { colors, type ThemeMode } from "@/constants/theme";
import { useThemeMode } from "@/contexts/theme";
import { defaultCamperProfile, storageKeys, type CamperProfile } from "@/data/camperboss";
import { useStorage } from "@/hooks/use-storage";

function toNumber(value: string, fallback: number) {
  const parsed = Number(value.replace(",", "."));
  return Number.isFinite(parsed) ? parsed : fallback;
}

function Field({
  label,
  value,
  keyboardType,
  onChangeText
}: {
  label: string;
  value: string;
  keyboardType?: "default" | "numeric";
  onChangeText: (value: string) => void;
}) {
  return (
    <View style={{ gap: 7 }}>
      <Text selectable style={{ color: colors.textSoft, fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>{label}</Text>
      <TextInput
        keyboardType={keyboardType}
        onChangeText={onChangeText}
        placeholderTextColor={colors.muted}
        style={{
          backgroundColor: "rgba(255,255,255,0.05)",
          borderColor: colors.line,
          borderRadius: 12,
          borderWidth: 1,
          color: colors.text,
          fontSize: 16,
          fontWeight: "800",
          minHeight: 48,
          paddingHorizontal: 12
        }}
        value={value}
      />
    </View>
  );
}

export default function ProfileScreen() {
  const [profile, setProfile] = useStorage<CamperProfile>(storageKeys.camperProfile, defaultCamperProfile);
  const { mode, resolvedMode, setMode } = useThemeMode();
  const payload = profile;
  const update = (patch: Partial<CamperProfile>) => setProfile({ ...payload, ...patch });
  const payloadMargin = Math.max(0, payload.maxWeightKg - payload.currentWeightKg);
  const payloadPercent = payload.maxWeightKg > 0 ? (payload.currentWeightKg / payload.maxWeightKg) * 100 : 0;

  return (
    <ScreenShell>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ gap: 18, padding: 18, paddingBottom: 34 }}>
        <Card tint="rgba(13, 27, 34, 0.90)" accent={payloadPercent > 90 ? colors.red : colors.neon}>
          <View style={{ gap: 14 }}>
            <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 12 }}>
              <Pill label="Profilo mezzo" tone={colors.neonSoft} color={colors.neon} />
              <Settings2 color={colors.neon} size={28} strokeWidth={2.5} />
            </View>
            <Text selectable style={{ color: colors.text, fontSize: 30, fontWeight: "900" }}>{payload.nickname}</Text>
            <Text selectable style={{ color: colors.textSoft, fontSize: 15, lineHeight: 21 }}>
              {payload.brand} {payload.model} - {payload.year} - altezza {payload.heightCm} cm
            </Text>
            <ProgressBar value={payloadPercent} color={payloadPercent > 90 ? colors.red : colors.neon} />
            <Text selectable style={{ color: colors.text, fontSize: 13, fontVariant: ["tabular-nums"], fontWeight: "900" }}>
              Margine carico utile: {payloadMargin} kg
            </Text>
          </View>
        </Card>

        <SectionTitle kicker="Tema" title="Aspetto interfaccia" action={resolvedMode === "dark" ? "Scuro attivo" : "Chiaro attivo"} />
        <Card tint={colors.panelSolid} accent={colors.lilac}>
          <View style={{ gap: 12 }}>
            <Text selectable style={{ color: colors.textSoft, fontSize: 14, lineHeight: 20 }}>
              Scegli un tema fisso oppure lascia CamperBoss sincronizzato con il telefono.
            </Text>
            <View style={{ flexDirection: "row", gap: 10 }}>
              {[
                { value: "auto" as ThemeMode, label: "Auto", icon: MonitorSmartphone },
                { value: "light" as ThemeMode, label: "Chiaro", icon: Sun },
                { value: "dark" as ThemeMode, label: "Scuro", icon: Moon }
              ].map((option) => {
                const Icon = option.icon;
                const active = mode === option.value;
                return (
                  <ElasticPressable
                    key={option.value}
                    onPress={() => setMode(option.value)}
                    scaleTo={0.94}
                    style={{
                      alignItems: "center",
                      backgroundColor: active ? colors.lilacSoft : "rgba(255,255,255,0.05)",
                      borderColor: active ? colors.lilac : colors.line,
                      borderRadius: 14,
                      borderWidth: 1,
                      flex: 1,
                      gap: 8,
                      minHeight: 76,
                      justifyContent: "center",
                      padding: 10
                    }}
                  >
                    <Icon color={active ? colors.lilac : colors.textSoft} size={21} strokeWidth={2.5} />
                    <Text selectable style={{ color: active ? colors.text : colors.textSoft, fontSize: 13, fontWeight: "900" }}>{option.label}</Text>
                  </ElasticPressable>
                );
              })}
            </View>
          </View>
        </Card>

        <SectionTitle kicker="Identita" title="Il tuo camper" />
        <Card tint={colors.panelSolid} accent={colors.cyan}>
          <View style={{ gap: 14 }}>
            <View style={{ alignItems: "center", flexDirection: "row", gap: 10 }}>
              <UserRound color={colors.cyan} size={22} strokeWidth={2.5} />
              <Text selectable style={{ color: colors.text, fontSize: 18, fontWeight: "900" }}>Anagrafica mezzo</Text>
            </View>
            <Field label="Nome" value={payload.nickname} onChangeText={(value) => update({ nickname: value })} />
            <Field label="Marca" value={payload.brand} onChangeText={(value) => update({ brand: value })} />
            <Field label="Modello" value={payload.model} onChangeText={(value) => update({ model: value })} />
            <Field label="Anno" keyboardType="numeric" value={payload.year} onChangeText={(value) => update({ year: value })} />
          </View>
        </Card>

        <SectionTitle kicker="Assetto tecnico" title="Dati per calcoli reali" />
        <Card tint={colors.panelSolid} accent={colors.neon}>
          <View style={{ gap: 14 }}>
            <View style={{ alignItems: "center", flexDirection: "row", gap: 10 }}>
              <Ruler color={colors.neon} size={22} strokeWidth={2.5} />
              <Text selectable style={{ color: colors.text, fontSize: 18, fontWeight: "900" }}>Misure e autonomia</Text>
            </View>
            <Field label="Altezza cm" keyboardType="numeric" value={String(payload.heightCm)} onChangeText={(value) => update({ heightCm: toNumber(value, payload.heightCm) })} />
            <Field label="Massa massima kg" keyboardType="numeric" value={String(payload.maxWeightKg)} onChangeText={(value) => update({ maxWeightKg: toNumber(value, payload.maxWeightKg) })} />
            <Field label="Peso attuale kg" keyboardType="numeric" value={String(payload.currentWeightKg)} onChangeText={(value) => update({ currentWeightKg: toNumber(value, payload.currentWeightKg) })} />
            <Field label="Acqua chiare litri" keyboardType="numeric" value={String(payload.waterLiters)} onChangeText={(value) => update({ waterLiters: toNumber(value, payload.waterLiters) })} />
            <Field label="Batteria servizi Ah" keyboardType="numeric" value={String(payload.batteryAh)} onChangeText={(value) => update({ batteryAh: toNumber(value, payload.batteryAh) })} />
            <Field label="Solare watt" keyboardType="numeric" value={String(payload.solarWatts)} onChangeText={(value) => update({ solarWatts: toNumber(value, payload.solarWatts) })} />
            <Field label="Bombole gas" keyboardType="numeric" value={String(payload.gasBottles)} onChangeText={(value) => update({ gasBottles: toNumber(value, payload.gasBottles) })} />
            <Field label="Persone a bordo" keyboardType="numeric" value={String(payload.people)} onChangeText={(value) => update({ people: toNumber(value, payload.people) })} />
            <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 12 }}>
              <View style={{ flex: 1, gap: 4 }}>
                <Text selectable style={{ color: colors.text, fontSize: 16, fontWeight: "900" }}>Pet a bordo</Text>
                <Text selectable style={{ color: colors.textSoft, fontSize: 13 }}>Attiva checklist e alert dedicati.</Text>
              </View>
              <Switch value={payload.petOnBoard} onValueChange={(value) => update({ petOnBoard: value })} />
            </View>
          </View>
        </Card>

        <Card tint="rgba(66, 217, 135, 0.10)" accent={colors.green}>
          <View style={{ alignItems: "center", flexDirection: "row", gap: 12 }}>
            <Weight color={colors.green} size={24} strokeWidth={2.5} />
            <View style={{ flex: 1, gap: 4 }}>
              <Text selectable style={{ color: colors.text, fontSize: 17, fontWeight: "900" }}>Salvataggio automatico</Text>
              <Text selectable style={{ color: colors.textSoft, fontSize: 13 }}>Ogni modifica aggiorna cockpit, planner e checklist.</Text>
            </View>
            <Save color={colors.green} size={20} strokeWidth={2.5} />
          </View>
        </Card>
      </ScrollView>
    </ScreenShell>
  );
}
