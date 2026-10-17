import type { EditorBlip, IconOption, PermissionOption } from '../../types';
import { BlipThumb } from '../BlipThumb';

interface BlipRowProps {
  blip: EditorBlip;
  icons: IconOption[];
  permissions: PermissionOption[];
  onOpen: (blip: EditorBlip) => void;
}

function describePermission(value: unknown, permissions: PermissionOption[]) {
  if (value === 'none' || value == null) return 'Everyone';
  if (typeof value !== 'string') return 'Custom';

  return permissions.find((permission) => permission.value === value)?.label ?? value;
}

export function BlipRow({ blip, icons, permissions, onOpen }: BlipRowProps) {
  const { data } = blip;
  const follows = data.player != null ? 'Follows a player' : data.entity != null ? 'Follows a vehicle' : null;

  return (
    <button className="row" onClick={() => onOpen(blip)}>
      <BlipThumb sprite={data.sprite} colour={data.colour} icon={data.icon} icons={icons} />
      <span className="row__text">
        <span className="row__title">{data.label}</span>
        <span className="row__meta">
          {describePermission(data.permissions, permissions)}
          {data.icon && ` · ${data.icon}`}
          {follows && ` · ${follows}`}
        </span>
      </span>
      {!blip.saved && <span className="badge">{blip.owner}</span>}
    </button>
  );
}
