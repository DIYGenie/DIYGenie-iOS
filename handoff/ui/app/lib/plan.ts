export type Plan = {
  overview?: string;
  skill_level?: 'beginner' | 'intermediate' | 'advanced';
  materials?: { 
    name: string; 
    qty?: string; 
    unit?: string; 
    price?: number;
    note?: string;
  }[];
  tools?: { 
    name: string; 
    have?: boolean; // true = probably have, false = need to buy/rent
    rental_price?: number;
  }[];
  cuts?: { part: string; width?: string; height?: string; size: string; qty?: number }[];
  steps?: {
    title?: string;
    body?: string;
    time_minutes?: number;
    materials_needed?: string[];
    tools_needed?: string[];
    purpose?: string;
    inputs?: string[];
    instructions?: string[];
    checks?: string[];
    pitfalls?: string[];
  }[];
  finishing?: {
    title?: string;
    description?: string;
  }[];
  time_estimate_hours?: number;
  cost_estimate_usd?: number;
  safety_warnings?: string[];
};

function getSection(md: string, title: string): string {
  const re = new RegExp(`^#{1,3}\\s*${title}\\s*$([\\s\\S]*?)(?=^#{1,3}\\s*\\w|\\Z)`, 'gim');
  const m = re.exec(md);
  return m ? m[1].trim() : '';
}

function bulletsToArray(block: string): string[] {
  return block
    .split('\n')
    .map((l) => l.trim().replace(/^[-*]\s+/, ''))
    .filter((l) => !!l);
}

export function parsePlanMarkdown(md: string): Plan {
  const plan: Plan = {};

  const overviewBlock = getSection(md, 'Overview') || md.split('\n\n')[0] || '';
  plan.overview = overviewBlock.replace(/^#+\s.*$/gm, '').trim();

  const matsBlock = getSection(md, 'Materials');
  if (matsBlock) {
    const list = bulletsToArray(matsBlock).map((line) => {
      const m = line.match(/^(.+?)[—-]\s*(.+)$/) || line.match(/^(.+?)\s{2,}(.+)$/);
      if (m) return { name: m[1].trim(), qty: m[2].trim() };
      return { name: line.trim() };
    });
    plan.materials = list;
  }

  const toolsBlock = getSection(md, 'Tools');
  if (toolsBlock) {
    plan.tools = bulletsToArray(toolsBlock).map(tool => ({ name: tool }));
  }

  const cutsBlock = getSection(md, 'Cut List') || getSection(md, 'Cuts');
  if (cutsBlock) {
    plan.cuts = bulletsToArray(cutsBlock).map((line) => {
      const qtyMatch = line.match(/×\s*(\d+)/) || line.match(/\(x\s*(\d+)\)/i);
      const qty = qtyMatch ? Number(qtyMatch[1]) : undefined;
      const partMatch = line.split(':');
      if (partMatch.length > 1) {
        return { part: partMatch[0].trim(), size: partMatch.slice(1).join(':').replace(/×\s*\d+|\(x\s*\d+\)/gi, '').trim(), qty };
      }
      return { part: 'Cut', size: line.replace(/×\s*\d+|\(x\s*\d+\)/gi, '').trim(), qty };
    });
  }

  const stepsBlock = getSection(md, 'Steps') || getSection(md, 'Instructions');
  if (stepsBlock) {
    const lines = stepsBlock.split('\n').filter(Boolean);
    const steps: { title?: string; body?: string }[] = [];
    let cur: { title?: string; body?: string } | null = null;
    for (const ln of lines) {
      const n = ln.match(/^(\d+)\.\s*(.+)$/);
      if (n) {
        if (cur) steps.push(cur);
        const fullText = n[2].trim();
        
        // Extract short title from markdown (e.g., "**Apply finish** - rest of text" -> "Apply finish")
        let title = fullText;
        let body = '';
        
        // Try to extract bold text as title
        const boldMatch = fullText.match(/^\*\*(.+?)\*\*\s*[-—]\s*(.+)$/);
        if (boldMatch) {
          title = boldMatch[1].trim();
          body = boldMatch[2].trim();
        } else {
          // Try to split on first dash/em-dash
          const dashMatch = fullText.match(/^(.+?)\s*[-—]\s*(.+)$/);
          if (dashMatch) {
            title = dashMatch[1].replace(/\*\*/g, '').trim();
            body = dashMatch[2].trim();
          } else {
            // Use first sentence as title if no dash
            const sentenceMatch = fullText.match(/^([^.!?]+[.!?])\s*(.*)$/);
            if (sentenceMatch && sentenceMatch[1].length < 80) {
              title = sentenceMatch[1].replace(/\*\*/g, '').trim();
              body = sentenceMatch[2].trim();
            } else {
              title = fullText.replace(/\*\*/g, '').trim();
            }
          }
        }
        
        cur = { title, body: body || undefined };
      } else if (/^[-*]\s+/.test(ln)) {
        if (cur) { steps.push(cur); cur = null; }
        steps.push({ title: ln.replace(/^[-*]\s+/, '').trim() });
      } else if (cur) {
        cur.body = ((cur.body || '') + '\n' + ln).trim();
      }
    }
    if (cur) steps.push(cur);
    plan.steps = steps.length ? steps : undefined;
  }

  const tcBlock = getSection(md, 'Time & Cost') || getSection(md, 'Estimates');
  if (tcBlock) {
    const time = tcBlock.match(/(\d+(\.\d+)?)\s*(hours|hrs|h)/i);
    const cost = tcBlock.match(/\$?\s*(\d+(\.\d+)?)/);
    if (time) plan.time_estimate_hours = Number(time[1]);
    if (cost) plan.cost_estimate_usd = Number(cost[1]);
  }

  return plan;
}

const PRICE_BOOK: Record<string, number> = {
  '2x4 lumber': 4.0,
  '2x6 lumber': 6.5,
  '2x8 lumber': 9.0,
  'Plywood 4x8': 35.0,
  'Wood glue': 6.5,
  '1 1/4 inch screws': 7.0,
  '2 inch screws': 8.5,
  'Primer': 12.0,
  'Paint (quart)': 15.0,
  'Sandpaper pack': 8.0,
  'Wall anchors': 8.0,
  'Wood stain': 18.0,
  'Finishing nails': 5.5,
  'Corner brackets': 10.0,
  'Shelf pins': 6.0,
};

interface Material {
  name: string;
  qty: number;
  unit: string;
  unitPrice: number;
}

interface Tool {
  name: string;
  have?: boolean;
  rentalPrice?: number;
  substitute?: string;
}

interface CutListItem {
  part: string;
  qty: number;
  length: string;
  width: string;
  thickness: string;
  notes?: string;
}

interface Step {
  stepNumber: number;
  title: string;
  description: string;
  estimatedTime?: string;
  timeMinutes?: number;
  materialsNeeded?: string[];
  toolsNeeded?: string[];
}

export interface BuildPlan {
  overview: string[];
  materials: Material[];
  tools: Tool[];
  steps: Step[];
  cutList: CutListItem[];
  estimatedTotal: number;
}

function hashString(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash);
}

function deriveCutListFromAR(project: any): CutListItem[] {
  return [
    { part: 'Shelf board (AR)', qty: 3, length: '36"', width: '10"', thickness: '3/4"', notes: 'Derived from AR scan' },
    { part: 'Vertical support (AR)', qty: 2, length: '48"', width: '2"', thickness: '3/4"', notes: 'Cut to measured height' },
    { part: 'Back panel (AR)', qty: 1, length: '36"', width: '48"', thickness: '1/4"', notes: 'Optional backing' },
  ];
}

function deriveCutListDefault(project: any): CutListItem[] {
  const hash = hashString(project.id || 'default');
  const variants = [
    [
      { part: 'Shelf board', qty: 3, length: '36"', width: '10"', thickness: '3/4"', notes: 'Edge sanded' },
      { part: 'Vertical support', qty: 2, length: '48"', width: '3.5"', thickness: '3/4"', notes: 'Pre-drilled' },
      { part: 'Back panel', qty: 1, length: '36"', width: '48"', thickness: '1/4"', notes: 'Optional' },
    ],
    [
      { part: 'Top piece', qty: 1, length: '42"', width: '12"', thickness: '3/4"', notes: 'Finished edge' },
      { part: 'Side panels', qty: 2, length: '30"', width: '12"', thickness: '3/4"', notes: 'Match grain' },
      { part: 'Bottom shelf', qty: 1, length: '40"', width: '11"', thickness: '3/4"', notes: 'Support brackets' },
      { part: 'Divider', qty: 1, length: '28"', width: '11"', thickness: '3/4"', notes: 'Center mount' },
    ],
    [
      { part: 'Frame rails', qty: 4, length: '24"', width: '2"', thickness: '1"', notes: 'Mitered corners' },
      { part: 'Cross braces', qty: 2, length: '22"', width: '2"', thickness: '1"', notes: 'Center support' },
      { part: 'Panel inserts', qty: 2, length: '20"', width: '20"', thickness: '1/2"', notes: 'Flush mount' },
    ],
  ];
  
  return variants[hash % variants.length];
}

function generateMaterialsForProject(project: any): Material[] {
  const hash = hashString(project.id || 'default');
  const baseSkill = project.skill || 'beginner';
  
  const materialSets = [
    [
      { name: '2x4 lumber', qty: 6, unit: 'pcs', unitPrice: PRICE_BOOK['2x4 lumber'] },
      { name: 'Wood glue', qty: 1, unit: 'bottle', unitPrice: PRICE_BOOK['Wood glue'] },
      { name: '1 1/4 inch screws', qty: 1, unit: 'box', unitPrice: PRICE_BOOK['1 1/4 inch screws'] },
      { name: 'Sandpaper pack', qty: 1, unit: 'pack', unitPrice: PRICE_BOOK['Sandpaper pack'] },
      { name: 'Wood stain', qty: 1, unit: 'quart', unitPrice: PRICE_BOOK['Wood stain'] },
    ],
    [
      { name: 'Plywood 4x8', qty: 1, unit: 'sheet', unitPrice: PRICE_BOOK['Plywood 4x8'] },
      { name: '2x6 lumber', qty: 4, unit: 'pcs', unitPrice: PRICE_BOOK['2x6 lumber'] },
      { name: '2 inch screws', qty: 2, unit: 'box', unitPrice: PRICE_BOOK['2 inch screws'] },
      { name: 'Corner brackets', qty: 1, unit: 'pack', unitPrice: PRICE_BOOK['Corner brackets'] },
      { name: 'Primer', qty: 1, unit: 'quart', unitPrice: PRICE_BOOK['Primer'] },
      { name: 'Paint (quart)', qty: 2, unit: 'quart', unitPrice: PRICE_BOOK['Paint (quart)'] },
    ],
    [
      { name: '2x4 lumber', qty: 8, unit: 'pcs', unitPrice: PRICE_BOOK['2x4 lumber'] },
      { name: '2x8 lumber', qty: 2, unit: 'pcs', unitPrice: PRICE_BOOK['2x8 lumber'] },
      { name: 'Wood glue', qty: 2, unit: 'bottle', unitPrice: PRICE_BOOK['Wood glue'] },
      { name: '1 1/4 inch screws', qty: 2, unit: 'box', unitPrice: PRICE_BOOK['1 1/4 inch screws'] },
      { name: 'Finishing nails', qty: 1, unit: 'box', unitPrice: PRICE_BOOK['Finishing nails'] },
      { name: 'Wall anchors', qty: 1, unit: 'pack', unitPrice: PRICE_BOOK['Wall anchors'] },
      { name: 'Sandpaper pack', qty: 1, unit: 'pack', unitPrice: PRICE_BOOK['Sandpaper pack'] },
    ],
  ];
  
  return materialSets[hash % materialSets.length];
}

function generateToolsForProject(project: any): Tool[] {
  const hash = hashString(project.id || 'default');
  const baseSkill = project.skill || 'beginner';
  
  const toolSets = [
    [
      { name: 'Drill/driver', have: false, rentalPrice: 25, substitute: 'Manual screwdriver' },
      { name: 'Circular saw', have: false, rentalPrice: 35, substitute: 'Hand saw' },
      { name: 'Measuring tape', have: true },
      { name: 'Level', have: true },
      { name: 'Pencil', have: true },
      { name: 'Safety glasses', have: true },
    ],
    [
      { name: 'Miter saw', have: false, rentalPrice: 45, substitute: 'Hand saw with miter box' },
      { name: 'Drill/driver', have: false, rentalPrice: 25 },
      { name: 'Orbital sander', have: false, rentalPrice: 20, substitute: 'Sanding block' },
      { name: 'Clamps (4+)', have: false },
      { name: 'Measuring tape', have: true },
      { name: 'Square', have: true },
      { name: 'Paintbrush set', have: true },
      { name: 'Safety gear', have: true },
    ],
    [
      { name: 'Table saw', have: false, rentalPrice: 60, substitute: 'Circular saw with guide' },
      { name: 'Drill/driver', have: false, rentalPrice: 25 },
      { name: 'Jigsaw', have: false, rentalPrice: 30 },
      { name: 'Router', have: false, rentalPrice: 35, substitute: 'Chisel set' },
      { name: 'Clamps (6+)', have: false },
      { name: 'Measuring tape', have: true },
      { name: 'Level', have: true },
      { name: 'Safety equipment', have: true },
    ],
  ];
  
  return toolSets[hash % toolSets.length];
}

function generateStepsForProject(project: any): Step[] {
  const hash = hashString(project.id || 'default');
  const stepSets = [
    [
      { stepNumber: 1, title: 'Prepare workspace', description: 'Clear the area and gather all materials and tools. Ensure proper lighting and ventilation.', estimatedTime: '15 min', timeMinutes: 15, materialsNeeded: [], toolsNeeded: [] },
      { stepNumber: 2, title: 'Measure and mark', description: 'Take precise measurements and mark cutting lines on all lumber pieces.', estimatedTime: '20 min', timeMinutes: 20, materialsNeeded: ['2x4 lumber'], toolsNeeded: ['Measuring tape', 'Pencil'] },
      { stepNumber: 3, title: 'Cut pieces to size', description: 'Carefully cut all pieces according to the cut list. Double-check measurements before cutting.', estimatedTime: '30 min', timeMinutes: 30, materialsNeeded: ['2x4 lumber'], toolsNeeded: ['Circular saw', 'Safety glasses'] },
      { stepNumber: 4, title: 'Sand all surfaces', description: 'Sand all cut edges and surfaces smooth, starting with coarse grit and finishing with fine grit.', estimatedTime: '25 min', timeMinutes: 25, materialsNeeded: ['Sandpaper pack'], toolsNeeded: ['Orbital sander'] },
      { stepNumber: 5, title: 'Assemble frame', description: 'Pre-drill holes and assemble the main frame using wood glue and screws. Use clamps to hold pieces while securing.', estimatedTime: '45 min', timeMinutes: 45, materialsNeeded: ['Wood glue', '1 1/4 inch screws'], toolsNeeded: ['Drill/driver', 'Clamps'] },
      { stepNumber: 6, title: 'Apply finish', description: 'Apply stain or paint according to manufacturer instructions. Allow proper drying time between coats.', estimatedTime: '1-2 hours', timeMinutes: 90, materialsNeeded: ['Wood stain'], toolsNeeded: ['Paintbrush set'] },
      { stepNumber: 7, title: 'Final assembly', description: 'Complete final assembly, install hardware, and make any necessary adjustments.', estimatedTime: '30 min', timeMinutes: 30, materialsNeeded: [], toolsNeeded: ['Drill/driver', 'Level'] },
    ],
    [
      { stepNumber: 1, title: 'Review plans', description: 'Study the build plan and familiarize yourself with all steps before starting.', estimatedTime: '10 min' },
      { stepNumber: 2, title: 'Cut all pieces', description: 'Cut all lumber and plywood pieces to size according to the cut list.', estimatedTime: '45 min' },
      { stepNumber: 3, title: 'Pre-drill and countersink', description: 'Pre-drill all screw holes and countersink where needed for a flush finish.', estimatedTime: '30 min' },
      { stepNumber: 4, title: 'Build the base', description: 'Construct the base frame and ensure it is square using a measuring square.', estimatedTime: '40 min' },
      { stepNumber: 5, title: 'Attach vertical supports', description: 'Install vertical supports, ensuring they are plumb and securely fastened.', estimatedTime: '35 min' },
      { stepNumber: 6, title: 'Install shelves', description: 'Position and secure shelf boards at the desired heights. Check level for each shelf.', estimatedTime: '30 min' },
      { stepNumber: 7, title: 'Sand and finish', description: 'Sand entire project, then apply primer and paint or stain as desired.', estimatedTime: '2-3 hours' },
      { stepNumber: 8, title: 'Mount and secure', description: 'Mount the finished piece to the wall using appropriate anchors and hardware.', estimatedTime: '20 min' },
    ],
    [
      { stepNumber: 1, title: 'Set up work area', description: 'Organize workspace with tools within reach and materials staged for assembly.', estimatedTime: '15 min' },
      { stepNumber: 2, title: 'Cut components', description: 'Make all cuts according to the cut list, checking each piece for accuracy.', estimatedTime: '1 hour' },
      { stepNumber: 3, title: 'Route edges', description: 'Use a router to create decorative edges or smooth sharp corners as needed.', estimatedTime: '30 min' },
      { stepNumber: 4, title: 'Test fit pieces', description: 'Dry fit all components together before applying glue to ensure proper alignment.', estimatedTime: '20 min' },
      { stepNumber: 5, title: 'Glue and clamp', description: 'Apply wood glue to joints and use clamps to hold pieces securely while drying.', estimatedTime: '45 min' },
      { stepNumber: 6, title: 'Add reinforcement', description: 'Install corner brackets, screws, or other reinforcement hardware.', estimatedTime: '25 min' },
      { stepNumber: 7, title: 'Finish surfaces', description: 'Sand, stain, or paint all visible surfaces. Apply multiple coats as needed.', estimatedTime: '2-4 hours' },
    ],
  ];
  
  return stepSets[hash % stepSets.length];
}

function generateOverviewForProject(project: any): string[] {
  const hash = hashString(project.id || 'default');
  const overviews = [
    [
      'This project creates a functional and attractive storage solution',
      'Perfect for beginners with basic woodworking skills',
      'Estimated completion time: 4-6 hours over a weekend',
      'Can be customized with different finishes and dimensions',
      'All materials readily available at local hardware stores',
      'No specialized tools required beyond basic hand and power tools',
    ],
    [
      'Build a custom piece tailored to your exact space requirements',
      'Intermediate skill level recommended',
      'Project can be completed in 6-8 hours',
      'Uses standard lumber sizes for easy sourcing',
      'Professional-looking results with attention to detail',
      'Optional modifications for different styles and uses',
      'Includes tips for achieving a smooth, polished finish',
    ],
    [
      'Comprehensive build plan for a sturdy, long-lasting project',
      'Suitable for those with some woodworking experience',
      'Allow 8-10 hours for completion',
      'Designed for both functionality and aesthetics',
      'Step-by-step instructions ensure success',
      'Material list includes small buffer for waste',
      'Can be adapted for various room layouts and needs',
    ],
  ];
  
  return overviews[hash % overviews.length];
}

export function buildPlanFromProject(project: any): BuildPlan {
  const materials = generateMaterialsForProject(project);
  const tools = generateToolsForProject(project);
  const steps = generateStepsForProject(project);
  const overview = generateOverviewForProject(project);
  
  const cutList = project.has_ar_scan && project.measurements
    ? deriveCutListFromAR(project)
    : deriveCutListDefault(project);
  
  const estimatedTotal = materials.reduce((sum, material) => {
    return sum + (material.qty * material.unitPrice);
  }, 0);
  
  return {
    overview,
    materials,
    tools,
    steps,
    cutList,
    estimatedTotal,
  };
}

export function serializePlanToText(plan: BuildPlan, projectName: string = 'DIY Project'): string {
  let text = `DIY GENIE - DETAILED BUILD PLAN\n`;
  text += `Project: ${projectName}\n`;
  text += `Generated: ${new Date().toLocaleDateString()}\n`;
  text += `\n${'='.repeat(60)}\n\n`;
  
  text += `OVERVIEW\n${'-'.repeat(60)}\n`;
  plan.overview.forEach((item, idx) => {
    text += `${idx + 1}. ${item}\n`;
  });
  
  text += `\n${'='.repeat(60)}\n\n`;
  text += `MATERIALS & TOOLS\n${'-'.repeat(60)}\n\n`;
  text += `Materials:\n`;
  plan.materials.forEach((mat) => {
    text += `  - ${mat.name}: ${mat.qty} ${mat.unit} @ $${mat.unitPrice.toFixed(2)} each = $${(mat.qty * mat.unitPrice).toFixed(2)}\n`;
  });
  text += `\nEstimated Total: $${plan.estimatedTotal.toFixed(2)}\n`;
  
  text += `\nTools Needed:\n`;
  plan.tools.forEach((tool) => {
    text += `  - ${tool.name}`;
    if (tool.substitute) {
      text += ` (substitute: ${tool.substitute})`;
    }
    text += `\n`;
  });
  
  text += `\n${'='.repeat(60)}\n\n`;
  text += `CUT LIST\n${'-'.repeat(60)}\n`;
  plan.cutList.forEach((item) => {
    text += `${item.part}:\n`;
    text += `  Qty: ${item.qty} | Length: ${item.length} | Width: ${item.width} | Thickness: ${item.thickness}\n`;
    if (item.notes) {
      text += `  Notes: ${item.notes}\n`;
    }
    text += `\n`;
  });
  
  text += `${'='.repeat(60)}\n\n`;
  text += `BUILD STEPS\n${'-'.repeat(60)}\n\n`;
  plan.steps.forEach((step) => {
    text += `Step ${step.stepNumber}: ${step.title}`;
    if (step.estimatedTime) {
      text += ` (${step.estimatedTime})`;
    }
    text += `\n`;
    text += `${step.description}\n\n`;
  });
  
  text += `${'='.repeat(60)}\n`;
  text += `\nEnd of Build Plan\n`;
  text += `Generated by DIY Genie - Wish. See. Build.\n`;
  
  return text;
}
