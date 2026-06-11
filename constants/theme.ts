export type ThemeMode = "light" | "dark" | "auto";
export type ThemePalette = typeof darkColors;

export const darkColors = {
  bg: "#071116",
  bg2: "#0D1B22",
  panel: "rgba(17, 31, 39, 0.82)",
  panelSolid: "#111F27",
  panelSoft: "#162B34",
  line: "rgba(154, 184, 190, 0.20)",
  lineStrong: "rgba(255, 255, 255, 0.18)",
  text: "#F4FAFA",
  textSoft: "#B9CCD0",
  muted: "#7F9AA1",
  neon: "#FF8A2A",
  neonPastel: "#FFB86B",
  neonSoft: "#3B2418",
  cyan: "#31D7E6",
  cyanPastel: "#8DEEFF",
  cyanSoft: "#13333A",
  ice: "#C7F5FF",
  green: "#42D987",
  greenPastel: "#8AF0B7",
  greenSoft: "#123526",
  red: "#FF5C5C",
  redPastel: "#FF9A9A",
  redSoft: "#3B171C",
  yellow: "#FFD166",
  yellowPastel: "#FFE59B",
  yellowSoft: "#3B3218",
  lilac: "#BCA7FF",
  lilacSoft: "#292044",
  pink: "#FF86C8",
  pinkSoft: "#3A1A32",
  slate: "#223743",
  white: "#FFFFFF",
  black: "#050A0D",
  ink: "#F4FAFA",
  moss: "#42D987",
  lake: "#31D7E6",
  sun: "#FF8A2A",
  coral: "#FF5C5C",
  sky: "#13333A",
  mint: "#123526",
  amber: "#3B3218",
  rose: "#3B171C",
  night: "#071116",
  paper: "#071116"
};

export const lightColors = {
  bg: "#F7FAFC",
  bg2: "#FFFFFF",
  panel: "rgba(255, 255, 255, 0.88)",
  panelSolid: "#FFFFFF",
  panelSoft: "#EEF4F6",
  line: "rgba(20, 45, 55, 0.14)",
  lineStrong: "rgba(20, 45, 55, 0.22)",
  text: "#101B22",
  textSoft: "#40545D",
  muted: "#6D818A",
  neon: "#F97316",
  neonPastel: "#FF9B4A",
  neonSoft: "#FFF0E4",
  cyan: "#0891B2",
  cyanPastel: "#38C7DA",
  cyanSoft: "#E6F9FC",
  ice: "#0E7490",
  green: "#16A34A",
  greenPastel: "#42D987",
  greenSoft: "#E9FBEF",
  red: "#DC2626",
  redPastel: "#FF7A7A",
  redSoft: "#FDECEC",
  yellow: "#D99A00",
  yellowPastel: "#FFD166",
  yellowSoft: "#FFF7D9",
  lilac: "#7C3AED",
  lilacSoft: "#F0E9FF",
  pink: "#DB2777",
  pinkSoft: "#FCE7F3",
  slate: "#D9E5E8",
  white: "#FFFFFF",
  black: "#071116",
  ink: "#101B22",
  moss: "#16A34A",
  lake: "#0891B2",
  sun: "#F97316",
  coral: "#DC2626",
  sky: "#E6F9FC",
  mint: "#E9FBEF",
  amber: "#FFF7D9",
  rose: "#FDECEC",
  night: "#FFFFFF",
  paper: "#F7FAFC"
};

export const colors = { ...darkColors };

export const radii = {
  sm: 8,
  md: 14,
  lg: 22,
  xl: 28
};

export const shadow = {
  boxShadow: "0 18px 44px rgba(0, 0, 0, 0.34)"
};

export const glow = {
  orange: "0 0 24px rgba(255, 138, 42, 0.32)",
  cyan: "0 0 24px rgba(49, 215, 230, 0.26)"
};
