import { useMemo, useState } from 'react';
import { sprites, spriteLabel } from '../../data';
import { Modal } from '../ui/Modal';

interface SpritePickerProps {
  value: number;
  onPick: (sprite: number) => void;
  onClose: () => void;
}

export function SpritePicker({ value, onPick, onClose }: SpritePickerProps) {
  const [search, setSearch] = useState('');

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return sprites;

    return sprites.filter((sprite) => String(sprite.id) === query || sprite.name.includes(query.replace(/\s+/g, '_')));
  }, [search]);

  return (
    <Modal title="Choose a sprite" onClose={onClose}>
      <input
        className="input"
        autoFocus
        placeholder="Search by name or number"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      <div className="grid grid--sprites">
        {filtered.map((sprite) => (
          <button
            key={sprite.id}
            className={`grid__item${sprite.id === value ? ' grid__item--active' : ''}`}
            title={`${sprite.id}: ${spriteLabel(sprite)}`}
            onClick={() => onPick(sprite.id)}
          >
            <img src={sprite.url} alt="" loading="lazy" />
            <span>{sprite.id}</span>
          </button>
        ))}
      </div>
      {filtered.length === 0 && <p className="muted">No sprites match "{search}"</p>}
    </Modal>
  );
}
