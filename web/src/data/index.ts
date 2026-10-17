// GTA blip sprites and colours, generated from https://docs.fivem.net/docs/game-references/blips/

import coloursJson from './colours.json';
import spritesJson from './sprites.json';

export interface SpriteInfo {
  id: number;
  name: string;
  url: string;
}

export interface ColourInfo {
  id: number;
  name: string;
  hex: string;
}

export const sprites: SpriteInfo[] = spritesJson;
export const colours: ColourInfo[] = coloursJson;

const spriteById = new Map(sprites.map((sprite) => [sprite.id, sprite]));
const colourById = new Map(colours.map((colour) => [colour.id, colour]));

export const getSprite = (id: number) => spriteById.get(id);
export const getColour = (id: number) => colourById.get(id);

/** 'radar_police_station' becomes 'Police Station' */
export const spriteLabel = (sprite: SpriteInfo) =>
  sprite.name
    .replace(/^radar_/, '')
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

export const DISPLAY_OPTIONS = [
  { value: 2, label: 'Map and minimap' },
  { value: 8, label: 'Map and minimap (not clickable)' },
  { value: 3, label: 'Pause map only' },
  { value: 5, label: 'Minimap only' },
];
