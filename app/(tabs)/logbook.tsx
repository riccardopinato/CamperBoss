import { Camera, MapPinned, Plus, ReceiptText, Route } from "lucide-react-native";
import { useState } from "react";
import { ScrollView, Text, View } from "react-native";
import { FormField, FormModal, today, toNumber } from "@/components/form";
import { Card, MapPreview, NeonButton, Pill, ScreenShell, SectionTitle } from "@/components/ui";
import { colors } from "@/constants/theme";
import { defaultTrips, storageKeys, type TripEntry } from "@/data/camperboss";
import { useStorage } from "@/hooks/use-storage";

export default function LogbookScreen() {
  const [trips, setTrips] = useStorage<TripEntry[]>(storageKeys.trips, defaultTrips);
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState({ place: "", km: "", mood: "", cost: "" });
  const totalKm = trips.reduce((sum, item) => sum + item.km, 0);
  const totalCost = trips.reduce((sum, item) => sum + item.cost, 0);

  const addTrip = () => {
    const entry: TripEntry = {
      id: `trip-${Date.now()}`,
      place: draft.place.trim() || "Nuova tappa",
      km: toNumber(draft.km, 0),
      mood: draft.mood.trim() || "Nota di viaggio",
      cost: toNumber(draft.cost, 0),
      date: today()
    };
    setTrips([entry, ...trips]);
    setDraft({ place: "", km: "", mood: "", cost: "" });
    setModalOpen(false);
  };

  return (
    <ScreenShell>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ gap: 18, padding: 18, paddingBottom: 34 }}>
        <Card tint="rgba(13, 27, 34, 0.88)" accent={colors.cyan}>
          <View style={{ gap: 16 }}>
            <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 12 }}>
              <Pill label="Digital logbook" tone={colors.cyanSoft} color={colors.cyan} />
              <Camera color={colors.cyan} size={28} strokeWidth={2.5} />
            </View>
            <Text selectable style={{ color: colors.text, fontSize: 29, fontWeight: "900" }}>Il viaggio diventa memoria visuale.</Text>
            <View style={{ flexDirection: "row", gap: 10 }}>
              <View style={{ backgroundColor: "rgba(255,255,255,0.05)", borderColor: colors.line, borderRadius: 14, borderWidth: 1, flex: 1, padding: 12 }}>
                <Route color={colors.neon} size={20} strokeWidth={2.5} />
                <Text selectable style={{ color: colors.text, fontSize: 25, fontVariant: ["tabular-nums"], fontWeight: "900", marginTop: 8 }}>{totalKm}</Text>
                <Text selectable style={{ color: colors.textSoft, fontSize: 12, fontWeight: "800" }}>km tracciati</Text>
              </View>
              <View style={{ backgroundColor: "rgba(255,255,255,0.05)", borderColor: colors.line, borderRadius: 14, borderWidth: 1, flex: 1, padding: 12 }}>
                <ReceiptText color={colors.green} size={20} strokeWidth={2.5} />
                <Text selectable style={{ color: colors.text, fontSize: 25, fontVariant: ["tabular-nums"], fontWeight: "900", marginTop: 8 }}>{totalCost}</Text>
                <Text selectable style={{ color: colors.textSoft, fontSize: 12, fontWeight: "800" }}>EUR spesi</Text>
              </View>
            </View>
          </View>
        </Card>

        <MapPreview />

        <SectionTitle kicker="Timeline" title="Ultime tappe" />
        {trips.map((item, index) => (
          <Card key={item.id} tint={index === 0 ? "rgba(255, 138, 42, 0.12)" : colors.panelSolid} accent={index === 0 ? colors.neon : colors.lineStrong}>
            <View style={{ gap: 10 }}>
              <View style={{ alignItems: "center", flexDirection: "row", gap: 12 }}>
                <View style={{ alignItems: "center", backgroundColor: colors.neonSoft, borderRadius: 999, height: 40, justifyContent: "center", width: 40 }}>
                  <MapPinned color={colors.neon} size={20} strokeWidth={2.5} />
                </View>
                <View style={{ flex: 1, gap: 4 }}>
                  <Text selectable style={{ color: colors.text, fontSize: 19, fontWeight: "900" }}>{item.place}</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 14 }}>{item.mood}</Text>
                </View>
                <Text selectable style={{ color: colors.cyan, fontSize: 14, fontVariant: ["tabular-nums"], fontWeight: "900" }}>{item.km} km</Text>
              </View>
              <Text selectable style={{ color: colors.textSoft, fontSize: 13, fontWeight: "800" }}>Costo registrato: {item.cost} EUR</Text>
              <Text selectable style={{ color: colors.muted, fontSize: 12, fontWeight: "800" }}>{item.date}</Text>
            </View>
          </Card>
        ))}

        <NeonButton label="Nuova tappa" icon={Plus} onPress={() => setModalOpen(true)} />
        <FormModal title="Nuova tappa" visible={modalOpen} onClose={() => setModalOpen(false)} onSave={addTrip}>
          <FormField label="Luogo" value={draft.place} onChangeText={(place) => setDraft({ ...draft, place })} />
          <FormField label="Km percorsi" keyboardType="numeric" value={draft.km} onChangeText={(km) => setDraft({ ...draft, km })} />
          <FormField label="Costo EUR" keyboardType="numeric" value={draft.cost} onChangeText={(cost) => setDraft({ ...draft, cost })} />
          <FormField label="Nota viaggio" multiline value={draft.mood} onChangeText={(mood) => setDraft({ ...draft, mood })} />
        </FormModal>
      </ScrollView>
    </ScreenShell>
  );
}
