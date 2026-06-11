import { Stack } from "expo-router/stack";
import { StatusBar } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { ThemeProvider, useThemeMode } from "@/contexts/theme";

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeProvider>
        <RootStack />
      </ThemeProvider>
    </GestureHandlerRootView>
  );
}

function RootStack() {
  const { colors, resolvedMode } = useThemeMode();

  return (
    <>
      <StatusBar barStyle={resolvedMode === "dark" ? "light-content" : "dark-content"} />
      <Stack
        screenOptions={{
          contentStyle: { backgroundColor: colors.bg },
          headerLargeTitle: true,
          headerShadowVisible: false,
          headerStyle: { backgroundColor: colors.bg },
          headerTintColor: colors.text
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack>
    </>
  );
}
