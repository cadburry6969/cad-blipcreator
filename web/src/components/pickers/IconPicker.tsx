import type { IconOption } from '../../types';
import { Modal } from '../ui/Modal';
import { IconLinkForm } from './IconLinkForm';

export interface IconActions {
  /** each returns an error message, or null when it worked */
  add: (name: string, url: string) => Promise<string | null>;
  remove: (name: string) => Promise<string | null>;
}

interface IconPickerProps {
  icons: IconOption[];
  value: string | null;
  actions: IconActions;
  onPick: (icon: string | null) => void;
  onClose: () => void;
}

export function IconPicker({ icons, value, actions, onPick, onClose }: IconPickerProps) {
  const add = async (name: string, url: string) => {
    const problem = await actions.add(name, url);
    if (!problem) onPick(name);

    return problem;
  };

  const remove = async (name: string) => {
    const problem = await actions.remove(name);
    if (!problem && value === name) onPick(null);
  };

  return (
    <Modal title="Choose a custom icon" onClose={onClose}>
      <IconLinkForm onAdd={add} />

      <div className="grid grid--icons">
        <button className={`grid__item${value === null ? ' grid__item--active' : ''}`} onClick={() => onPick(null)}>
          <span className="grid__none">None</span>
          <span>GTA sprite</span>
        </button>

        {icons.map((icon) => (
          <div key={icon.name} className="grid__cell">
            <button
              className={`grid__item${icon.name === value ? ' grid__item--active' : ''}`}
              title={icon.link ? icon.url : icon.name}
              onClick={() => onPick(icon.name)}
            >
              <img src={icon.url} alt="" />
              <span>{icon.name}</span>
            </button>

            {icon.link && (
              <button
                className="grid__remove"
                title="Remove this icon"
                aria-label={`Remove ${icon.name}`}
                onClick={() => void remove(icon.name)}
              >
                ✕
              </button>
            )}
          </div>
        ))}
      </div>
    </Modal>
  );
}
