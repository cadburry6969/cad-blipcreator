import { useMemo, useState } from 'react';
import type { EditorBlip, IconOption, PermissionOption } from '../../types';
import { BlipRow } from './BlipRow';
import { type Filters, ListFilters } from './ListFilters';

interface BlipListProps {
  blips: EditorBlip[];
  icons: IconOption[];
  permissions: PermissionOption[];
  onOpen: (blip: EditorBlip) => void;
  onCreate: () => void;
}

function matches(blip: EditorBlip, filters: Filters) {
  if (filters.source === 'saved' && !blip.saved) return false;
  if (filters.source === 'scripts' && blip.saved) return false;
  if (filters.permission !== 'any' && blip.data.permissions !== filters.permission) return false;

  const query = filters.search.trim().toLowerCase();
  if (!query) return true;

  return [blip.data.label, blip.id, blip.owner, blip.data.icon ?? ''].some((text) => text.toLowerCase().includes(query));
}

export function BlipList({ blips, icons, permissions, onOpen, onCreate }: BlipListProps) {
  const [filters, setFilters] = useState<Filters>({ search: '', source: 'all', permission: 'any' });

  const visible = useMemo(
    () =>
      blips
        .filter((blip) => matches(blip, filters))
        .sort((a, b) => Number(b.saved) - Number(a.saved) || a.data.label.localeCompare(b.data.label)),
    [blips, filters],
  );

  return (
    <div className="list">
      <ListFilters filters={filters} permissions={permissions} onChange={setFilters} />

      <div className="list__rows">
        {visible.map((blip) => (
          <BlipRow key={blip.id} blip={blip} icons={icons} permissions={permissions} onOpen={onOpen} />
        ))}
        {visible.length === 0 && <p className="muted list__empty">No blips found</p>}
      </div>

      <footer className="footer">
        <span className="muted">
          {visible.length} of {blips.length} blips
        </span>
        <button className="button button--primary" onClick={onCreate}>
          New blip
        </button>
      </footer>
    </div>
  );
}
