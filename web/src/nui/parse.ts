// Checks data coming from Lua before the UI uses it

import type {
  BlipData,
  EditorBlip,
  EditorResult,
  IconMutationResponse,
  IconOption,
  MutationResponse,
  NuiMessage,
  OpenPayload,
  PermissionOption,
  Vec3,
} from '../types';

type UnknownRecord = Record<string, unknown>;

const isRecord = (value: unknown): value is UnknownRecord =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const isNumber = (value: unknown): value is number => typeof value === 'number' && Number.isFinite(value);

const optionalNumber = (value: unknown): number | undefined => (isNumber(value) ? value : undefined);

const optionalString = (value: unknown): string | undefined => (typeof value === 'string' ? value : undefined);

/** Lua sends empty tables as {} instead of [], so both count as an empty list */
const toArray = (value: unknown): unknown[] => {
  if (Array.isArray(value)) return value;
  if (isRecord(value) && Object.keys(value).length === 0) return [];
  return [];
};

export function parseVec3(value: unknown): Vec3 | null {
  if (!isRecord(value) || !isNumber(value.x) || !isNumber(value.y)) return null;

  return { x: value.x, y: value.y, z: isNumber(value.z) ? value.z : 0 };
}

function parseBlipData(value: unknown): BlipData | null {
  if (!isRecord(value) || typeof value.label !== 'string') return null;
  if (!isNumber(value.sprite) || !isNumber(value.colour) || !isNumber(value.display)) return null;

  return {
    label: value.label,
    coords: parseVec3(value.coords) ?? undefined,
    sprite: value.sprite,
    colour: value.colour,
    scale: isNumber(value.scale) ? value.scale : 1,
    alpha: isNumber(value.alpha) ? value.alpha : 255,
    display: value.display,
    shortRange: value.shortRange !== false,
    permissions: value.permissions ?? 'none',
    flash: value.flash === true,
    category: optionalNumber(value.category),
    categoryLabel: optionalString(value.categoryLabel),
    radius: optionalNumber(value.radius),
    radiusColour: optionalNumber(value.radiusColour),
    radiusAlpha: optionalNumber(value.radiusAlpha),
    icon: optionalString(value.icon),
    iconSize: optionalNumber(value.iconSize),
    entity: optionalNumber(value.entity),
    player: optionalNumber(value.player),
  };
}

function parseBlip(value: unknown): EditorBlip | null {
  if (!isRecord(value) || typeof value.id !== 'string') return null;

  const data = parseBlipData(value.data);
  if (!data) return null;

  return {
    id: value.id,
    saved: value.saved === true,
    owner: typeof value.owner === 'string' ? value.owner : 'unknown',
    data,
  };
}

export function parseBlipList(value: unknown): EditorBlip[] {
  return toArray(value)
    .map(parseBlip)
    .filter((blip): blip is EditorBlip => blip !== null);
}

function parseIcon(value: unknown): IconOption | null {
  if (!isRecord(value) || typeof value.name !== 'string' || typeof value.url !== 'string') return null;

  return { name: value.name, url: value.url, link: value.link === true };
}

function parseIconList(value: unknown): IconOption[] {
  return toArray(value)
    .map(parseIcon)
    .filter((icon): icon is IconOption => icon !== null);
}

function parsePermission(value: unknown): PermissionOption | null {
  if (!isRecord(value) || typeof value.label !== 'string' || typeof value.value !== 'string') return null;

  return { label: value.label, value: value.value };
}

function parseOpenPayload(value: unknown): OpenPayload | null {
  if (!isRecord(value)) return null;

  return {
    blips: parseBlipList(value.blips),
    icons: parseIconList(value.icons),
    permissions: toArray(value.permissions)
      .map(parsePermission)
      .filter((permission): permission is PermissionOption => permission !== null),
    player: parseVec3(value.player) ?? { x: 0, y: 0, z: 0 },
  };
}

export function parseMessage(value: unknown): NuiMessage | null {
  if (!isRecord(value)) return null;

  switch (value.action) {
    case 'open': {
      const data = parseOpenPayload(value.data);
      return data ? { action: 'open', data } : null;
    }
    case 'hide': {
      const hint = isRecord(value.data) ? optionalString(value.data.hint) : undefined;
      return { action: 'hide', hint: hint ?? null };
    }
    case 'close':
    case 'show':
      return { action: value.action };
    default:
      return null;
  }
}

function parseResult(value: unknown): EditorResult | null {
  if (!isRecord(value) || typeof value.ok !== 'boolean') return null;

  return { ok: value.ok, id: optionalString(value.id), error: optionalString(value.error) };
}

export function parseMutation(value: unknown): MutationResponse {
  if (!isRecord(value)) return { result: null, blips: null };

  return {
    result: parseResult(value.result),
    blips: value.blips == null ? null : parseBlipList(value.blips),
  };
}

export function parseIconMutation(value: unknown): IconMutationResponse {
  if (!isRecord(value)) return { result: null, icons: null };

  return {
    result: parseResult(value.result),
    icons: value.icons == null ? null : parseIconList(value.icons),
  };
}
