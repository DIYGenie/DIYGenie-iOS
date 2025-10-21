import type { Plan } from './plan';

export function countLabel(n?: number, word = 'item') {
  if (!n) return `No ${word}s`;
  return `${n} ${n === 1 ? word : word + 's'}`;
}

export function stepsTimeCost(p?: Plan) {
  if (!p) return 'No steps yet';
  const steps = p.steps?.length ? `${p.steps.length} steps` : 'No steps';
  const time = p.time_estimate_hours ? `${p.time_estimate_hours} hrs` : '— hrs';
  const cost = p.cost_estimate_usd ? `~$${p.cost_estimate_usd}` : '—';
  return `${steps} • ${time} • ${cost}`;
}
