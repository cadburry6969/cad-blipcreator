import { getColour, getSprite } from '../data';
import type { IconOption } from '../types';

interface BlipThumbProps {
  sprite: number;
  colour: number;
  icon?: string | null;
  icons: IconOption[];
}

/** Small picture of a blip: its custom icon, or its GTA sprite with a colour dot */
export function BlipThumb({ sprite, colour, icon, icons }: BlipThumbProps) {
  const iconUrl = icon ? icons.find((option) => option.name === icon)?.url : undefined;
  const spriteUrl = getSprite(sprite)?.url;
  const hex = getColour(colour)?.hex ?? '#ffffff';

  return (
    <span className="thumb">
      {iconUrl || spriteUrl ? (
        <img src={iconUrl ?? spriteUrl} alt="" loading="lazy" />
      ) : (
        <span className="thumb__fallback">{sprite}</span>
      )}
      {!iconUrl && <span className="thumb__colour" style={{ background: hex }} />}
    </span>
  );
}
