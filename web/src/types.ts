// Shapes shared with the Lua side (client/editor.lua and server/editor.lua)

export type Vec3 = { x: number; y: number; z: number };

/** Blip fields as the Lua side stores them. Script blips may use fields the editor doesn't show. */
export interface BlipData {
  label: string;
  coords?: Vec3;
  sprite: number;
  colour: number;
  scale: number;
  alpha: number;
  display: number;
  shortRange: boolean;
  permissions: unknown;
  flash?: boolean;
  category?: number;
  categoryLabel?: string;
  radius?: number;
  radiusColour?: number;
  radiusAlpha?: number;
  icon?: string;
  iconSize?: number;
  entity?: number;
  player?: number;
}

export interface EditorBlip {
  id: string;
  /** saved blips are editable, the rest were created by scripts */
  saved: boolean;
  owner: string;
  data: BlipData;
}

export interface IconOption {
  name: string;
  url: string;
  /** added from a link in the editor, so it can be removed there */
  link: boolean;
}

export interface PermissionOption {
  label: string;
  value: string;
}

export interface OpenPayload {
  blips: EditorBlip[];
  icons: IconOption[];
  permissions: PermissionOption[];
  player: Vec3;
}

export interface EditorResult {
  ok: boolean;
  id?: string;
  error?: string;
}

export interface MutationResponse {
  result: EditorResult | null;
  blips: EditorBlip[] | null;
}

export interface IconMutationResponse {
  result: EditorResult | null;
  icons: IconOption[] | null;
}

export type NuiMessage =
  | { action: 'open'; data: OpenPayload }
  | { action: 'close' }
  | { action: 'hide'; hint: string | null }
  | { action: 'show' };

export type PositionSource = 'player' | 'waypoint';
