// The editor form state, and conversion to and from the blip data Lua uses

import type { BlipData, Vec3 } from './types';

export interface Draft {
  label: string;
  coords: Vec3;
  sprite: number;
  colour: number;
  scale: number;
  alpha: number;
  display: number;
  shortRange: boolean;
  flash: boolean;
  permissions: string;
  category: number | null;
  categoryLabel: string;
  radius: number | null;
  radiusColour: number | null;
  radiusAlpha: number;
  icon: string | null;
  iconSize: number;
}

export function newDraft(coords: Vec3): Draft {
  return {
    label: 'New blip',
    coords,
    sprite: 1,
    colour: 0,
    scale: 1,
    alpha: 255,
    display: 2,
    shortRange: true,
    flash: false,
    permissions: 'none',
    category: null,
    categoryLabel: '',
    radius: null,
    radiusColour: null,
    radiusAlpha: 128,
    icon: null,
    iconSize: 24,
  };
}

export function draftFromBlip(data: BlipData, fallbackCoords: Vec3): Draft {
  return {
    label: data.label,
    coords: data.coords ?? fallbackCoords,
    sprite: data.sprite,
    colour: data.colour,
    scale: data.scale,
    alpha: data.alpha,
    display: data.display,
    shortRange: data.shortRange,
    flash: data.flash === true,
    permissions: typeof data.permissions === 'string' ? data.permissions : 'none',
    category: data.category ?? null,
    categoryLabel: data.categoryLabel ?? '',
    radius: data.radius ?? null,
    radiusColour: data.radiusColour ?? null,
    radiusAlpha: data.radiusAlpha ?? 128,
    icon: data.icon ?? null,
    iconSize: data.iconSize ?? 24,
  };
}

/** Blip fields sent to Lua. Empty optional fields are left out. */
export function draftToBlip(draft: Draft): Record<string, unknown> {
  const blip: Record<string, unknown> = {
    label: draft.label.trim(),
    coords: draft.coords,
    sprite: draft.sprite,
    colour: draft.colour,
    scale: draft.scale,
    alpha: draft.alpha,
    display: draft.display,
    shortRange: draft.shortRange,
    flash: draft.flash,
    permissions: draft.permissions,
  };

  if (draft.category != null) {
    blip.category = draft.category;
    if (draft.categoryLabel.trim()) blip.categoryLabel = draft.categoryLabel.trim();
  }

  if (draft.radius != null) {
    blip.radius = draft.radius;
    blip.radiusAlpha = draft.radiusAlpha;
    if (draft.radiusColour != null) blip.radiusColour = draft.radiusColour;
  }

  if (draft.icon != null) {
    blip.icon = draft.icon;
    blip.iconSize = draft.iconSize;
  }

  return blip;
}

/** Problems shown before saving. The server checks again. */
export function validateDraft(draft: Draft): string | null {
  const label = draft.label.trim();

  if (label.length < 1 || label.length > 64) return 'Name must be 1 to 64 characters';
  if (Math.abs(draft.coords.x) > 10000 || Math.abs(draft.coords.y) > 10000) return 'Position is outside the map';
  if (draft.category != null && (draft.category < 1 || draft.category > 255)) return 'Category must be 1 to 255';
  if (draft.radius != null && (draft.radius < 1 || draft.radius > 5000)) return 'Radius must be 1 to 5000';

  return null;
}
