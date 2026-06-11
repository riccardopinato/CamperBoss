import { FileText, Plus, ShieldCheck, Wrench } from "lucide-react-native";
import { useState } from "react";
import { ScrollView, Text, View } from "react-native";
import { FormField, FormModal, today, toNumber } from "@/components/form";
import { Card, NeonButton, ProgressBar, ScreenShell, SectionTitle } from "@/components/ui";
import { colors } from "@/constants/theme";
import { defaultServiceLogs, storageKeys, type ServiceLogEntry } from "@/data/camperboss";
import { useStorage } from "@/hooks/use-storage";

function statusColor(status: string) {
  if (status === "urgent") return colors.red;
  if (status === "watch") return colors.yellow;
  return colors.green;
}

export default function GarageScreen() {
  const [serviceLogs, setServiceLogs] = useStorage<ServiceLogEntry[]>(storageKeys.serviceLogs, defaultServiceLogs);
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState({ title: "", due: "", cost: "", note: "" });

  const addServiceLog = () => {
    const entry: ServiceLogEntry = {
      id: `service-${Date.now()}`,
      title: draft.title.trim() || "Intervento service",
      due: draft.due.trim() || "nessuna scadenza",
      progress: 18,
      status: "safe",
      cost: toNumber(draft.cost, 0),
      note: draft.note.trim() || "Intervento registrato manualmente.",
      date: today()
    };
    setServiceLogs([entry, ...serviceLogs]);
    setDraft({ title: "", due: "", cost: "", note: "" });
    setModalOpen(false);
  };

  return (
    <ScreenShell>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={{ gap: 18, padding: 18, paddingBottom: 34 }}>
        <Card tint="rgba(17, 31, 39, 0.82)" accent={colors.green}>
          <View style={{ alignItems: "center", flexDirection: "row", gap: 12 }}>
            <ShieldCheck color={colors.green} size={30} strokeWidth={2.7} />
            <View style={{ flex: 1, gap: 4 }}>
              <Text selectable style={{ color: colors.text, fontSize: 26, fontWeight: "900" }}>Garage service</Text>
              <Text selectable style={{ color: colors.textSoft, fontSize: 14, lineHeight: 20 }}>Il valore del camper, certificato intervento dopo intervento.</Text>
            </View>
          </View>
        </Card>

        <SectionTitle kicker="Manutenzione predittiva" title="Scadenze e rischio" />
        {serviceLogs.map((item) => (
          <Card key={item.title} tint={item.status === "urgent" ? colors.redSoft : colors.panelSolid} accent={statusColor(item.status)}>
            <View style={{ gap: 12 }}>
              <View style={{ alignItems: "flex-start", flexDirection: "row", gap: 12 }}>
                <View style={{ alignItems: "center", backgroundColor: `${statusColor(item.status)}22`, borderRadius: 999, height: 40, justifyContent: "center", width: 40 }}>
                  <Wrench color={statusColor(item.status)} size={20} strokeWidth={2.5} />
                </View>
                <View style={{ flex: 1, gap: 5 }}>
                  <Text selectable style={{ color: colors.text, fontSize: 18, fontWeight: "900" }}>{item.title}</Text>
                  <Text selectable style={{ color: colors.textSoft, fontSize: 14 }}>{item.due}</Text>
                  <Text selectable style={{ color: colors.muted, fontSize: 13 }}>{item.note}</Text>
                </View>
                <Text selectable style={{ color: statusColor(item.status), fontSize: 12, fontWeight: "900" }}>{item.status.toUpperCase()}</Text>
              </View>
              <ProgressBar value={item.progress} color={statusColor(item.status)} />
              {item.cost > 0 ? <Text selectable style={{ color: colors.textSoft, fontSize: 13, fontWeight: "800" }}>Costo: {item.cost.toFixed(0)} EUR</Text> : null}
            </View>
          </Card>
        ))}

        <Card tint="rgba(49, 215, 230, 0.10)" accent={colors.cyan}>
          <View style={{ gap: 12 }}>
            <FileText color={colors.cyan} size={26} strokeWidth={2.5} />
            <Text selectable style={{ color: colors.text, fontSize: 23, fontWeight: "900" }}>Manuale del mio camper</Text>
            <Text selectable style={{ color: colors.textSoft, fontSize: 14, lineHeight: 20 }}>
              Upgrade, fatture, diagnosi e foto in una timeline pronta per garanzia, rivendita e memoria tecnica.
            </Text>
            <NeonButton label="Registra intervento" icon={Plus} onPress={() => setModalOpen(true)} />
          </View>
        </Card>
        <FormModal title="Nuovo intervento" visible={modalOpen} onClose={() => setModalOpen(false)} onSave={addServiceLog}>
          <FormField label="Titolo intervento" value={draft.title} onChangeText={(title) => setDraft({ ...draft, title })} />
          <FormField label="Scadenza o promemoria" value={draft.due} onChangeText={(due) => setDraft({ ...draft, due })} />
          <FormField label="Costo EUR" keyboardType="numeric" value={draft.cost} onChangeText={(cost) => setDraft({ ...draft, cost })} />
          <FormField label="Note" multiline value={draft.note} onChangeText={(note) => setDraft({ ...draft, note })} />
        </FormModal>
      </ScrollView>
    </ScreenShell>
  );
}
