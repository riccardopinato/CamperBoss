import type React from "react";
import { createContext, useContext, useMemo } from "react";
import { useColorScheme } from "react-native";
import { colors, darkColors, lightColors, type ThemeMode, type ThemePalette } from "@/constants/theme";
import { useStorage } from "@/hooks/use-storage";

const THEME_STORAGE_KEY = "camperboss.themeMode";

type ThemeContextValue = {
  colors: ThemePalette;
  mode: ThemeMode;
  resolvedMode: "light" | "dark";
  setMode: (mode: ThemeMode) => void;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const systemScheme = useColorScheme();
  const [mode, setMode] = useStorage<ThemeMode>(THEME_STORAGE_KEY, "auto");
  const resolvedMode = mode === "auto" ? (systemScheme === "dark" ? "dark" : "light") : mode;
  const palette = resolvedMode === "dark" ? darkColors : lightColors;

  Object.assign(colors, palette);

  const value = useMemo(
    () => ({
      colors: palette,
      mode,
      resolvedMode,
      setMode
    }),
    [mode, palette, resolvedMode, setMode]
  );

  return (
    <ThemeContext.Provider value={value}>
      <ThemeRootKey key={resolvedMode}>{children}</ThemeRootKey>
    </ThemeContext.Provider>
  );
}

function ThemeRootKey({ children }: { children: React.ReactNode }) {
  return children;
}

export function useThemeColors() {
  return useThemeMode().colors;
}

export function useThemeMode() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error("useThemeMode must be used inside ThemeProvider");
  }

  return context;
}
