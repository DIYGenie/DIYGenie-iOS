export function formatPlanText(project: any, plan: any): string {
  const name = (project?.name ?? 'DIY Project').trim();
  const status = project?.status ?? '—';
  const updated = (project?.updated_at ?? '').toString().slice(0,10);

  const ov = plan?.overview ?? {};
  const materials = Array.isArray(plan?.materials) ? plan.materials : [];
  const tools = Array.isArray(plan?.tools) ? plan.tools : [];
  const cuts = Array.isArray(plan?.cuts) ? plan.cuts : [];
  const steps = Array.isArray(plan?.steps) ? plan.steps : [];

  const lines: string[] = [];
  lines.push(`${name}`);
  lines.push(`Status: ${status}   Updated: ${updated}`);
  lines.push('');
  lines.push('OVERVIEW');
  const ovBits = [
    ov.est_time ? `Time: ${ov.est_time}` : '',
    ov.est_cost ? `Cost: ${ov.est_cost}` : '',
    ov.skill ? `Skill: ${ov.skill}` : '',
  ].filter(Boolean).join('   ');
  if (ovBits) lines.push(`• ${ovBits}`);
  if (ov.notes) lines.push(String(ov.notes));
  lines.push('');

  lines.push(`MATERIALS (${materials.length})`);
  for (const m of materials) {
    const qty = m?.qty ? `${m.qty} ` : '';
    const notes = m?.notes ? ` (${m.notes})` : '';
    const name = (m?.name ?? m?.item ?? '').toString().trim();
    if (name) lines.push(`- ${qty}${name}${notes}`);
  }
  lines.push('');

  lines.push(`TOOLS (${tools.length})`);
  for (const t of tools) {
    const name = (t?.name ?? t?.tool ?? '').toString().trim();
    const notes = t?.notes ? ` (${t.notes})` : '';
    if (name) lines.push(`- ${name}${notes}`);
  }
  lines.push('');

  lines.push(`CUT LIST (${cuts.length})`);
  for (const c of cuts) {
    const qty = c?.qty ? `${c.qty} ` : '';
    const item = (c?.item ?? c?.name ?? '').toString().trim();
    const size = c?.size ? ` — ${c.size}` : '';
    const notes = c?.notes ? ` (${c.notes})` : '';
    if (item) lines.push(`- ${qty}${item}${size}${notes}`);
  }
  lines.push('');

  lines.push(`STEPS (${steps.length})`);
  let n = 1;
  for (const s of steps) {
    const text = (s?.text ?? s?.step ?? '').toString().trim();
    const notes = s?.notes ? ` (${s.notes})` : '';
    if (text) lines.push(`${n++}) ${text}${notes}`);
  }

  const out = lines.join('\n');
  return out.length > 15000 ? out.slice(0,14980) + '\n…' : out;
}
