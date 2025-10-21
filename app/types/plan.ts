export interface PlanSummary {
  title: string;
  heroImageUrl?: string;
  estTimeHours?: number;
  estCostUsd?: number;
}

export interface PlanPreview {
  beforeUrl?: string;
  afterUrl?: string;
}

export interface PlanMaterial {
  qty: number;
  unit: string;
  name: string;
  subtotalUsd?: number;
}

export interface PlanTools {
  required?: string[];
  optional?: string[];
}

export interface PlanCutItem {
  board: string;
  dims: string;
  qty: number;
}

export interface PlanCutList {
  items?: PlanCutItem[];
  layoutSvgUrl?: string;
}

export interface PlanStep {
  title: string;
  text: string;
  diagramUrl?: string;
}

export interface PlanSafety {
  notes?: string[];
}

export interface PlanPermits {
  needed?: boolean;
  note?: string;
}

export interface PlanQuota {
  blocked?: boolean;
  message?: string;
}

export interface PlanResponse {
  ok: boolean;
  error?: string;
  summary?: PlanSummary;
  preview?: PlanPreview;
  materials?: PlanMaterial[];
  tools?: PlanTools;
  cutList?: PlanCutList;
  steps?: PlanStep[];
  safety?: PlanSafety;
  permits?: PlanPermits;
  quota?: PlanQuota;
}
