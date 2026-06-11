import { Tabs } from "expo-router";
import { BookOpen, Gauge, Map, Settings2, Siren, Wrench } from "lucide-react-native";
import type { ColorValue } from "react-native";
import { colors } from "@/constants/theme";

function tabIcon(Icon: typeof Gauge) {
  return ({ color, focused }: { color: ColorValue; focused: boolean }) => (
    <Icon color={focused ? colors.neon : String(color)} size={22} strokeWidth={focused ? 2.8 : 2.2} />
  );
}

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShadowVisible: false,
        headerStyle: { backgroundColor: colors.bg },
        headerTintColor: colors.text,
        sceneStyle: { backgroundColor: colors.bg },
        tabBarActiveTintColor: colors.neon,
        tabBarInactiveTintColor: colors.muted,
        tabBarLabelStyle: { fontSize: 11, fontWeight: "800" },
        tabBarStyle: {
          backgroundColor: "#0A151A",
          borderTopColor: colors.line,
          minHeight: 70,
          paddingBottom: 8,
          paddingTop: 8
        }
      }}
    >
      <Tabs.Screen name="index" options={{ title: "Cockpit", tabBarIcon: tabIcon(Gauge) }} />
      <Tabs.Screen name="sos" options={{ title: "SOS", tabBarIcon: tabIcon(Siren) }} />
      <Tabs.Screen name="planner" options={{ title: "Planner", tabBarIcon: tabIcon(Map) }} />
      <Tabs.Screen name="garage" options={{ title: "Garage", tabBarIcon: tabIcon(Wrench) }} />
      <Tabs.Screen name="logbook" options={{ title: "Diario", tabBarIcon: tabIcon(BookOpen) }} />
      <Tabs.Screen name="profile" options={{ title: "Profilo", tabBarIcon: tabIcon(Settings2) }} />
    </Tabs>
  );
}
