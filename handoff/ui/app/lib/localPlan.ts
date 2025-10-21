import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = (id: string) => `plan-md:${id}`;

export const saveLocalPlanMarkdown = (id: string, md: string) => AsyncStorage.setItem(KEY(id), md);
export const getLocalPlanMarkdown = (id: string) => AsyncStorage.getItem(KEY(id));

export function generateLocalPlanMarkdown({ title, description, budget, skill_level }: any = {}) {
  return `# ${title ?? 'Project'}

**Overview**  
${description ?? 'A custom DIY project.'}

## Materials
- Plywood — 2 sheets
- 2x4 studs — 6
- Wood screws — 1 lb
- Wood glue — 1 bottle

## Tools
- Circular saw
- Drill/driver
- Tape measure
- Square
- Safety glasses

## Cut List
- Side panel: 24" × 18" ×2
- Shelf: 24" × 10" ×3
- Top/bottom: 24" × 12" ×2

## Steps
1. Measure and mark all cuts.
2. Rip panels.
3. Assemble carcass.
4. Add shelves.
5. Sand & finish.

## Time & Cost
- Time: 6–8 hours
- Cost: ~${budget ?? '$$'} (skill: ${skill_level ?? 'Intermediate'})
`;
}
