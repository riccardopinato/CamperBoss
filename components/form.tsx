import type React from "react";
import { Modal, ScrollView, Text, TextInput, View } from "react-native";
import { Check, X } from "lucide-react-native";
import { colors, radii } from "@/constants/theme";
import { ElasticPressable, NeonButton } from "@/components/ui";

export function FormModal({
  title,
  visible,
  onClose,
  onSave,
  children
}: {
  title: string;
  visible: boolean;
  onClose: () => void;
  onSave: () => void;
  children: React.ReactNode;
}) {
  return (
    <Modal animationType="slide" transparent visible={visible} onRequestClose={onClose}>
      <View style={{ backgroundColor: "rgba(0,0,0,0.62)", flex: 1, justifyContent: "flex-end" }}>
        <View style={{ backgroundColor: colors.bg2, borderColor: colors.lineStrong, borderTopLeftRadius: 26, borderTopRightRadius: 26, borderWidth: 1, maxHeight: "88%", padding: 18 }}>
          <View style={{ alignItems: "center", flexDirection: "row", gap: 12, justifyContent: "space-between", marginBottom: 12 }}>
            <Text selectable style={{ color: colors.text, flex: 1, fontSize: 22, fontWeight: "900" }}>{title}</Text>
            <ElasticPressable onPress={onClose} style={{ alignItems: "center", backgroundColor: colors.panelSoft, borderRadius: 999, height: 38, justifyContent: "center", width: 38 }}>
              <X color={colors.textSoft} size={20} strokeWidth={2.6} />
            </ElasticPressable>
          </View>
          <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={{ gap: 14, paddingBottom: 16 }}>
            {children}
            <NeonButton label="Salva dati" icon={Check} onPress={onSave} />
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

export function FormField({
  label,
  value,
  onChangeText,
  keyboardType = "default",
  multiline
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  keyboardType?: "default" | "numeric";
  multiline?: boolean;
}) {
  return (
    <View style={{ gap: 7 }}>
      <Text selectable style={{ color: colors.textSoft, fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>{label}</Text>
      <TextInput
        keyboardType={keyboardType}
        multiline={multiline}
        onChangeText={onChangeText}
        placeholderTextColor={colors.muted}
        style={{
          backgroundColor: "rgba(255,255,255,0.06)",
          borderColor: colors.line,
          borderRadius: radii.md,
          borderWidth: 1,
          color: colors.text,
          fontSize: 16,
          fontWeight: "800",
          minHeight: multiline ? 96 : 50,
          paddingHorizontal: 12,
          paddingTop: multiline ? 12 : undefined,
          textAlignVertical: multiline ? "top" : "center"
        }}
        value={value}
      />
    </View>
  );
}

export function toNumber(value: string, fallback = 0) {
  const normalized = value.replace(",", ".").trim();
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function today() {
  return new Date().toISOString().slice(0, 10);
}
