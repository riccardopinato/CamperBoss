import type React from "react";
import { LinearGradient } from "expo-linear-gradient";
import type { LucideIcon } from "lucide-react-native";
import { Pressable, Text, View, type StyleProp, type ViewStyle } from "react-native";
import Animated, { FadeInUp, useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
import { colors, radii, shadow } from "@/constants/theme";

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export function ElasticPressable({
  children,
  onPress,
  style,
  scaleTo = 0.965
}: {
  children: React.ReactNode;
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
  scaleTo?: number;
}) {
  const scale = useSharedValue(1);
  const lift = useSharedValue(0);
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }, { translateY: lift.value }]
  }));

  return (
    <AnimatedPressable
      onPress={onPress}
      onPressIn={() => {
        scale.value = withSpring(scaleTo, { damping: 14, stiffness: 260 });
        lift.value = withSpring(2, { damping: 14, stiffness: 260 });
      }}
      onPressOut={() => {
        scale.value = withSpring(1, { damping: 12, stiffness: 220 });
        lift.value = withSpring(0, { damping: 12, stiffness: 220 });
      }}
      style={[style, animatedStyle]}
    >
      {children}
    </AnimatedPressable>
  );
}

export function ScreenShell({ children }: { children: React.ReactNode }) {
  return (
    <LinearGradient colors={[colors.bg, colors.bg2, "#101A1E"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={{ flex: 1 }}>
      {children}
    </LinearGradient>
  );
}

export function SectionTitle({ kicker, title, action }: { kicker?: string; title: string; action?: string }) {
  return (
    <View style={{ gap: 6 }}>
      {kicker ? <Text selectable style={{ color: colors.cyan, fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>{kicker}</Text> : null}
      <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 12 }}>
        <Text selectable style={{ color: colors.text, flex: 1, fontSize: 23, fontWeight: "900" }}>{title}</Text>
        {action ? <Text selectable style={{ color: colors.neon, fontSize: 13, fontWeight: "900" }}>{action}</Text> : null}
      </View>
    </View>
  );
}

export function Card({ children, tint = colors.panelSolid, accent }: { children: React.ReactNode; tint?: string; accent?: string }) {
  return (
    <Animated.View
      entering={FadeInUp.duration(380).springify().damping(18)}
      style={{
        backgroundColor: tint,
        borderColor: accent ?? colors.line,
        borderRadius: radii.lg,
        borderWidth: 1,
        overflow: "hidden",
        padding: 16,
        ...shadow
      }}
    >
      {accent ? <View style={{ backgroundColor: accent, height: 3, left: 16, position: "absolute", right: 16, top: 0 }} /> : null}
      {children}
    </Animated.View>
  );
}

export function Pill({ label, tone = colors.cyanSoft, color = colors.ice }: { label: string; tone?: string; color?: string }) {
  return (
    <View style={{ alignSelf: "flex-start", backgroundColor: tone, borderColor: colors.lineStrong, borderRadius: 999, borderWidth: 1, paddingHorizontal: 10, paddingVertical: 6 }}>
      <Text selectable style={{ color, fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>{label}</Text>
    </View>
  );
}

export function ProgressBar({ value, color = colors.cyan }: { value: number; color?: string }) {
  return (
    <View style={{ backgroundColor: "rgba(255,255,255,0.10)", borderRadius: 999, height: 10, overflow: "hidden" }}>
      <View style={{ backgroundColor: color, borderRadius: 999, height: "100%", width: `${Math.max(4, Math.min(100, value))}%` }} />
    </View>
  );
}

export function NeonButton({
  label,
  icon: Icon,
  onPress,
  danger
}: {
  label: string;
  icon: LucideIcon;
  onPress?: () => void;
  danger?: boolean;
}) {
  const primary = danger ? colors.red : colors.neon;
  return (
    <ElasticPressable
      onPress={onPress}
      scaleTo={0.94}
    >
      <LinearGradient
        colors={danger ? ["#FF6A57", "#D63F45"] : ["#FFB14A", "#FF7A1A"]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={{
          alignItems: "center",
          borderRadius: radii.md,
          flexDirection: "row",
          gap: 10,
          justifyContent: "center",
          minHeight: 50,
          paddingHorizontal: 16,
          paddingVertical: 13,
          boxShadow: `0 0 28px ${primary}44`
        }}
      >
        <Icon color={colors.black} size={18} strokeWidth={2.8} />
        <Text selectable style={{ color: colors.black, fontSize: 14, fontWeight: "900" }}>{label}</Text>
      </LinearGradient>
    </ElasticPressable>
  );
}

export function IconButton({ label, symbol, onPress, danger }: { label: string; symbol: string; onPress?: () => void; danger?: boolean }) {
  return (
    <ElasticPressable
      onPress={onPress}
      scaleTo={0.95}
      style={{
        alignItems: "center",
        backgroundColor: danger ? colors.red : colors.panelSoft,
        borderColor: danger ? colors.red : colors.lineStrong,
        borderRadius: radii.md,
        borderWidth: 1,
        flexDirection: "row",
        gap: 8,
        justifyContent: "center",
        minHeight: 46,
        paddingHorizontal: 14,
        paddingVertical: 12
      }}
    >
      <Text selectable style={{ color: colors.white, fontSize: 15, fontWeight: "900" }}>{symbol}</Text>
      <Text selectable style={{ color: colors.white, fontSize: 14, fontWeight: "900" }}>{label}</Text>
    </ElasticPressable>
  );
}

export function BentoTile({
  children,
  accent = colors.cyan,
  tint = colors.panelSolid,
  size = "small",
  onPress
}: {
  children: React.ReactNode;
  accent?: string;
  tint?: string;
  size?: "small" | "wide" | "hero";
  onPress?: () => void;
}) {
  const basis = size === "hero" || size === "wide" ? "100%" : "48%";
  const minHeight = size === "hero" ? 210 : size === "wide" ? 150 : 132;

  return (
    <ElasticPressable onPress={onPress} scaleTo={onPress ? 0.975 : 1} style={{ flexBasis: basis, flexGrow: 1 }}>
      <LinearGradient
        colors={[tint, "rgba(255,255,255,0.045)"]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={{
          borderColor: accent,
          borderRadius: radii.xl,
          borderWidth: 1,
          minHeight,
          overflow: "hidden",
          padding: 16,
          ...shadow
        }}
      >
        <View style={{ backgroundColor: accent, borderRadius: 999, height: 6, position: "absolute", right: 16, top: 16, width: 42 }} />
        {children}
      </LinearGradient>
    </ElasticPressable>
  );
}

export function MetricTile({ label, value, detail, icon: Icon, color = colors.cyan }: { label: string; value: string; detail?: string; icon: LucideIcon; color?: string }) {
  return (
    <Card tint="rgba(17, 31, 39, 0.72)" accent={color}>
      <View style={{ gap: 12 }}>
        <View style={{ alignItems: "center", flexDirection: "row", justifyContent: "space-between", gap: 10 }}>
          <Text selectable style={{ color: colors.textSoft, flex: 1, fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>{label}</Text>
          <View style={{ alignItems: "center", backgroundColor: `${color}22`, borderRadius: 999, height: 34, justifyContent: "center", width: 34 }}>
            <Icon color={color} size={18} strokeWidth={2.4} />
          </View>
        </View>
        <Text selectable style={{ color: colors.text, fontSize: 25, fontWeight: "900" }}>{value}</Text>
        {detail ? <Text selectable style={{ color: colors.muted, fontSize: 12, lineHeight: 17 }}>{detail}</Text> : null}
      </View>
    </Card>
  );
}

export function MapPreview() {
  const pins = [
    { left: 48, top: 98, color: colors.neon },
    { left: 136, top: 62, color: colors.cyan },
    { left: 232, top: 104, color: colors.green }
  ];

  return (
    <View style={{ backgroundColor: "#0A161B", borderColor: colors.line, borderRadius: radii.lg, borderWidth: 1, height: 170, overflow: "hidden" }}>
      <LinearGradient colors={["#12242B", "#091318"]} style={{ flex: 1 }}>
        {[0, 1, 2, 3].map((line) => (
          <View key={`h-${line}`} style={{ backgroundColor: "rgba(199,245,255,0.10)", height: 1, left: 0, position: "absolute", right: 0, top: 34 + line * 34 }} />
        ))}
        {[0, 1, 2, 3].map((line) => (
          <View key={`v-${line}`} style={{ backgroundColor: "rgba(199,245,255,0.08)", bottom: 0, position: "absolute", top: 0, width: 1, left: 42 + line * 68 }} />
        ))}
        <View style={{ backgroundColor: colors.neon, borderRadius: 999, height: 4, left: 34, position: "absolute", right: 40, top: 92, transform: [{ rotate: "-10deg" }] }} />
        <View style={{ backgroundColor: colors.cyan, borderRadius: 999, height: 3, left: 104, position: "absolute", right: 24, top: 66, transform: [{ rotate: "24deg" }] }} />
        {pins.map((pin) => (
          <View key={`${pin.left}-${pin.top}`} style={{ backgroundColor: pin.color, borderColor: colors.white, borderRadius: 999, borderWidth: 2, height: 18, left: pin.left, position: "absolute", top: pin.top, width: 18 }} />
        ))}
        <View style={{ bottom: 14, left: 14, position: "absolute", right: 14 }}>
          <Text selectable style={{ color: colors.text, fontSize: 18, fontWeight: "900" }}>Explorer layer</Text>
          <Text selectable style={{ color: colors.textSoft, fontSize: 12, marginTop: 3 }}>Aree sosta, scarichi, acqua, rischio altezza</Text>
        </View>
      </LinearGradient>
    </View>
  );
}
