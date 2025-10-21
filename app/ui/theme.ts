export const colors = {
  bg: "#FFFFFF",
  text: "#111827",
  sub: "#6B7280",
  border: "#E5E7EB",
  card: "#F9FAFB",
  primary: "#7C3AED",
  primaryText: "#FFFFFF",
  successBg: "#E8F6EE",
  successText: "#2E7D32",
  mutedBg: "#F3F4F6",
  mutedText: "#374151",
};

export const radii = { xs: 6, sm: 10, md: 14, lg: 18, pill: 999 };
export const space = { xs: 6, sm: 10, md: 14, lg: 20, xl: 28 };
export const shadow = {
  card: { shadowColor: "#000", shadowOpacity: 0.05, shadowRadius: 8, elevation: 2 },
};

export const ui = {
  h1: { fontSize: 22, fontWeight: "800" as const, color: colors.text },
  h2: { fontSize: 18, fontWeight: "700" as const, color: colors.text },
  p:  { fontSize: 14, color: colors.text },
  sub:{ fontSize: 13, color: colors.sub },
};
