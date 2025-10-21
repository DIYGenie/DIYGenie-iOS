function simpleHash(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash);
}

export interface PlanStep {
  id: string;
  title: string;
  details?: string;
}

export interface PlanMaterial {
  id: string;
  name: string;
  qty: number;
  unit?: string;
  estCost?: number;
}

export interface PlanTool {
  id: string;
  name: string;
  alt?: string;
}

export interface PlanTip {
  id: string;
  body: string;
}

export interface PlanStubs {
  overview: {
    intro: string;
    steps: PlanStep[];
  };
  materials: PlanMaterial[];
  tools: PlanTool[];
  tips: PlanTip[];
}

const stepTemplates = [
  'Prepare your workspace and gather all materials',
  'Measure and mark the cutting lines accurately',
  'Cut the wood pieces according to measurements',
  'Sand all surfaces smooth with 120-grit sandpaper',
  'Apply wood stain or primer evenly',
  'Assemble the main frame using wood glue',
  'Secure joints with screws or nails',
  'Install hardware and finishing touches',
  'Apply protective finish or sealant',
  'Allow proper drying time before use',
];

const materialTemplates = [
  { name: 'Pine boards', unit: 'ft', baseCost: 3.50 },
  { name: 'Wood screws', unit: 'box', baseCost: 8.99 },
  { name: 'Wood glue', unit: 'bottle', baseCost: 6.49 },
  { name: 'Sandpaper pack', unit: 'pack', baseCost: 12.99 },
  { name: 'Wood stain', unit: 'can', baseCost: 15.99 },
  { name: 'Finishing nails', unit: 'box', baseCost: 5.49 },
  { name: 'L-brackets', unit: 'set', baseCost: 9.99 },
  { name: 'Polyurethane sealant', unit: 'can', baseCost: 18.99 },
  { name: 'Paint brushes', unit: 'set', baseCost: 11.49 },
];

const toolTemplates = [
  { name: 'Circular saw', alt: 'Hand saw' },
  { name: 'Power drill', alt: 'Manual screwdriver' },
  { name: 'Measuring tape', alt: null },
  { name: 'Level', alt: 'Smartphone level app' },
  { name: 'Clamps', alt: 'Heavy books for weight' },
  { name: 'Safety glasses', alt: null },
  { name: 'Pencil', alt: 'Marker' },
  { name: 'Square', alt: 'Ruler and protractor' },
];

const tipTemplates = [
  'Always measure twice and cut once to avoid waste',
  'Work in a well-ventilated area when using stains or finishes',
  'Pre-drill holes to prevent wood from splitting',
  'Sand in the direction of the wood grain for best results',
  'Use painter\'s tape to create clean edges when staining',
  'Allow adequate drying time between coats',
  'Keep your work area clean and organized for safety',
  'Test finishes on scrap wood before applying to project',
];

export function getPlanStubs(projectId: string): PlanStubs {
  if (!projectId || projectId === 'undefined') {
    return {
      overview: {
        intro: 'Plan details not available yet.',
        steps: [],
      },
      materials: [],
      tools: [],
      tips: [],
    };
  }

  const hash = simpleHash(projectId);
  const stepCount = 6 + (hash % 5);
  const materialCount = 5 + (hash % 4);
  const toolCount = 5 + (hash % 4);
  const tipCount = 4 + (hash % 5);

  const steps: PlanStep[] = [];
  for (let i = 0; i < stepCount; i++) {
    const templateIndex = (hash + i) % stepTemplates.length;
    steps.push({
      id: `step-${i + 1}`,
      title: stepTemplates[templateIndex],
      details: `Detailed instructions for step ${i + 1} would go here.`,
    });
  }

  const materials: PlanMaterial[] = [];
  for (let i = 0; i < materialCount; i++) {
    const templateIndex = (hash + i) % materialTemplates.length;
    const template = materialTemplates[templateIndex];
    const qty = 1 + ((hash + i) % 4);
    materials.push({
      id: `mat-${i + 1}`,
      name: template.name,
      qty,
      unit: template.unit,
      estCost: template.baseCost * qty,
    });
  }

  const tools: PlanTool[] = [];
  for (let i = 0; i < toolCount; i++) {
    const templateIndex = (hash + i) % toolTemplates.length;
    const template = toolTemplates[templateIndex];
    tools.push({
      id: `tool-${i + 1}`,
      name: template.name,
      alt: template.alt || undefined,
    });
  }

  const tips: PlanTip[] = [];
  for (let i = 0; i < tipCount; i++) {
    const templateIndex = (hash + i) % tipTemplates.length;
    tips.push({
      id: `tip-${i + 1}`,
      body: tipTemplates[templateIndex],
    });
  }

  return {
    overview: {
      intro: `This ${stepCount}-step project will transform your space. Follow each step carefully for best results.`,
      steps,
    },
    materials,
    tools,
    tips,
  };
}
