import { colours } from '../../data';
import { Modal } from '../ui/Modal';

interface ColourPickerProps {
  title: string;
  value: number | null;
  onPick: (colour: number) => void;
  onClose: () => void;
}

export function ColourPicker({ title, value, onPick, onClose }: ColourPickerProps) {
  return (
    <Modal title={title} onClose={onClose}>
      <div className="grid grid--colours">
        {colours.map((colour) => (
          <button
            key={colour.id}
            className={`swatch${colour.id === value ? ' swatch--active' : ''}`}
            style={{ background: colour.hex }}
            title={`${colour.id}: ${colour.name}`}
            onClick={() => onPick(colour.id)}
          >
            <span>{colour.id}</span>
          </button>
        ))}
      </div>
    </Modal>
  );
}
