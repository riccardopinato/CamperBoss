import { useRouter } from "expo-router";
import { BatteryCharging, Check, CircleAlert, Droplets, Flame, Gauge, Route, ShieldCheck, Siren, WalletCards } from "lucide-react-native";
import { ScrollView, Text, View } from "react-native";
import { bossScore, defaultCamperProfile, hacks, storageKeys, tMinusChecklist, type CamperProfile } from "@/data/camperboss";
import { BentoTile, Card, ElasticPressable, MapPreview, NeonButton, Pill, ProgressBar, ScreenShell, SectionTitle } from "@/components/ui";
import { colors } from "@/constants/theme";
import { useStorage } from "@/hooks/use-storage";

export default function CockpitScreen() {
  const router = useRouter();
  const [profile] = useStorage<CamperProfile>(storageKeys.camperProfile, defaultCamperProfile);
  const [checklist, setChecklist] = useStorage(storageKeys.checklist, tMinusChecklist);
  const done = checklist.filter((item) => item.done).length;
  const xpProgress = (bossScore.xp / bossScore.next) * 100;
  const people = Math.max(1, profile.people);
  const waterDays = profile.waterLiters / (people * 18);
  const gasDays = profile.gasBottles * (profile.petOnBoard ? 3.8 : 4.5);
  const payloadMargin = Math.max(0, profile.maxWeightKg - profile.currentWeightKg);

  const toggleChecklist = (id: string) => {
    setChecklist(checklist.map((item) => (item.id === id ? { ...item, done: !item.done } : item)));
  };

  const metrics = [
    { label: "Acqua", value: `${waterDays.toFixed(1)} gg`, detail: `${profile.waterLiters} L / ${people} persone`, icon: Droplets, color: colors.cyanPastel, tint: colors.cyanSoft },
    { label: "Energia", value: `${profile.batteryAh} Ah`, detail: `${profile.solarWatts}W solare`, icon: BatteryCharging, color: colors.greenPastel, tint: colors.greenSoft },
    { label: "Gas", value: `${gasDays.toFixed(1)} gg`, detail: `${profile.gasBottles} bombole operative`, icon: Flame, color: colors.neonPastel, tint: colors.neonSoft },
    { label: "Peso", value: `${payloadMargin} kg`, detail: "margine carico utile", icon: Gauge, color: payloadMargin < 180 ? colors.redPastel : colors.yellowPastel, tint: payloadMargin < 180 ? colors.redSoft : colors.yellowSoft }
  ];

  return (
    <ScreenShell>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ gap: 18, padding: 18, paddingBottom: 34 }}>
        <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
          <BentoTile size="hero" tint="rgba(11, 24, 30, 0.95)" accent={colors.neonPastel}>
            <View style={{ flex: 1, gap: 18, justifyContent: "space-between" }}>
              <View style={{ gap: 18 }}>
                <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 12 }}>
                  <Pill label={`${profile.nickname} - level ${bossScore.level}`} tone={colors.neonSoft} color={colors.neonPastel} />
                  <View style={{ alignItems: "center", backgroundColor: colors.cyanSoft, borderRadius: 999, height: 42, justifyContent: "center", width: 42 }}>
                    <ShieldCheck color={colors.cyanPastel} size={22} strokeWidth={2.6} />
                  </View>
                </View>
                <View style={{ gap: 8 }}>
                  <Text selectable style={{ color: colors.text, fontSize: 34, fontWeight: "900" }}>CamperBoss Command</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 15, lineHeight: 22 }}>
                    {profile.brand} {profile.model}: autonomia, sicurezza, route layer e diagnostica pronti prima di muovere un metro.
                  </Text>
                </View>
              </View>
              <View style={{ gap: 8 }}>
                <ProgressBar value={xpProgress} color={colors.neonPastel} />
                <Text selectable style={{ color: colors.textSoft, fontSize: 13, fontVariant: ["tabular-nums"], fontWeight: "800" }}>
                  {bossScore.xp}/{bossScore.next} XP - {bossScore.badge} - streak {bossScore.streak} giorni
                </Text>
              </View>
              <NeonButton label="Apri SOS Diagnostica" icon={Siren} danger onPress={() => router.push("/sos")} />
            </View>
          </BentoTile>

          {metrics.map((metric) => {
            const Icon = metric.icon;
            return (
              <BentoTile key={metric.label} accent={metric.color} tint={metric.tint}>
                <View style={{ flex: 1, gap: 12, justifyContent: "space-between" }}>
                  <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 10 }}>
                    <Text selectable style={{ color: colors.textSoft, flex: 1, fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>{metric.label}</Text>
                    <View style={{ alignItems: "center", backgroundColor: "rgba(255,255,255,0.10)", borderRadius: 999, height: 34, justifyContent: "center", width: 34 }}>
                      <Icon color={metric.color} size={18} strokeWidth={2.5} />
                    </View>
                  </View>
                  <View style={{ gap: 6 }}>
                    <Text selectable style={{ color: colors.text, fontSize: 25, fontWeight: "900" }}>{metric.value}</Text>
                    <Text selectable style={{ color: colors.textSoft, fontSize: 12, lineHeight: 17 }}>{metric.detail}</Text>
                  </View>
                </View>
              </BentoTile>
            );
          })}
        </View>

        <MapPreview />

        <SectionTitle kicker="T-Minus protocol" title="Pre-partenza da comandante" action={`${done}/${checklist.length}`} />
        <Card tint="rgba(13, 27, 34, 0.86)" accent={done === checklist.length ? colors.green : colors.neon}>
          <View style={{ gap: 12 }}>
            {checklist.slice(0, 5).map((item) => (
              <ElasticPressable
                key={item.id}
                onPress={() => toggleChecklist(item.id)}
                scaleTo={0.97}
                style={{
                  alignItems: "flex-start",
                  backgroundColor: item.done ? colors.greenSoft : "rgba(255,255,255,0.04)",
                  borderColor: item.done ? "rgba(66,217,135,0.32)" : colors.line,
                  borderRadius: 12,
                  borderWidth: 1,
                  flexDirection: "row",
                  gap: 10,
                  padding: 12
                }}
              >
                <View style={{ alignItems: "center", backgroundColor: item.done ? colors.green : colors.redSoft, borderRadius: 999, height: 30, justifyContent: "center", width: 30 }}>
                  {item.done ? <Check color={colors.black} size={17} strokeWidth={3} /> : <CircleAlert color={colors.red} size={17} strokeWidth={2.8} />}
                </View>
                <View style={{ flex: 1, gap: 4 }}>
                  <Text selectable style={{ color: colors.text, fontSize: 15, fontWeight: "900" }}>{item.title}</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 13, lineHeight: 18 }}>{item.detail}</Text>
                </View>
              </ElasticPressable>
            ))}
          </View>
        </Card>

        <SectionTitle kicker="Camper Swipe" title="Hack da salvare nel manuale" />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 12 }}>
          {hacks.map((hack, index) => (
            <View key={hack.title} style={{ width: 276 }}>
              <Card tint={index === 0 ? colors.cyanSoft : colors.panelSolid} accent={index === 0 ? colors.cyan : colors.neon}>
                <View style={{ gap: 12 }}>
                  <View style={{ alignItems: "center", flexDirection: "row", gap: 10 }}>
                    <View style={{ alignItems: "center", backgroundColor: colors.neonSoft, borderRadius: 999, height: 36, justifyContent: "center", width: 36 }}>
                      <Route color={colors.neon} size={18} strokeWidth={2.5} />
                    </View>
                    <Pill label={hack.tag} />
                  </View>
                  <Text selectable style={{ color: colors.text, fontSize: 20, fontWeight: "900" }}>{hack.title}</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 14, lineHeight: 20 }}>{hack.body}</Text>
                </View>
              </Card>
            </View>
          ))}
        </ScrollView>

        <Card tint="rgba(255, 138, 42, 0.12)" accent={colors.neon}>
          <View style={{ alignItems: "center", flexDirection: "row", gap: 12 }}>
            <WalletCards color={colors.neon} size={24} strokeWidth={2.4} />
            <View style={{ flex: 1, gap: 3 }}>
              <Text selectable style={{ color: colors.text, fontSize: 17, fontWeight: "900" }}>Budget live</Text>
              <Text selectable style={{ color: colors.textSoft, fontSize: 13 }}>312 EUR stimati tra carburante, sosta, scarico e fondo emergenze.</Text>
            </View>
          </View>
        </Card>
      </ScrollView>
    </ScreenShell>
  );
}
