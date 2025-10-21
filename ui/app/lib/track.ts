const BASE =
  process.env.EXPO_PUBLIC_BASE_URL ||
  "https://diy-genie-webhooks-tyekowalski.replit.app";

type TrackArgs = {
  userId: string;
  event: "open_plan" | "delete_project" | "create_template" | string;
  projectId?: string | null;
  props?: Record<string, any>;
};

export async function track({ userId, event, projectId, props }: TrackArgs) {
  if (!userId || !event) return;
  try {
    await fetch(`${BASE}/api/events`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: userId,
        event_type: event,
        project_id: projectId ?? null,
        props: props ?? {},
      }),
    });
  } catch {
    // swallow — telemetry must never break UX
  }
}
