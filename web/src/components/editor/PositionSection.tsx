import type { PositionSource, Vec3 } from '../../types';
import { NumberInput } from '../ui/NumberInput';
import { Section } from '../ui/Section';
import type { SectionProps } from './sections';

interface PositionSectionProps extends SectionProps {
  onUsePosition: (source: PositionSource) => void;
  onPickOnMap: () => void;
  onCopy: () => void;
  onTeleport: () => void;
}

const AXES: (keyof Vec3)[] = ['x', 'y', 'z'];

export function PositionSection({
  draft,
  readOnly,
  onUpdate,
  onUsePosition,
  onPickOnMap,
  onCopy,
  onTeleport,
}: PositionSectionProps) {
  return (
    <Section title="Position">
      <div className="coords">
        {AXES.map((axis) => (
          <label key={axis} className="coords__axis">
            <span>{axis.toUpperCase()}</span>
            <NumberInput
              value={Math.round(draft.coords[axis] * 100) / 100}
              step={0.1}
              disabled={readOnly}
              onChange={(value) => onUpdate({ coords: { ...draft.coords, [axis]: value } })}
            />
          </label>
        ))}
      </div>

      {!readOnly && (
        <div className="button-row">
          <button className="button button--accent" onClick={onPickOnMap}>
            Pick on map
          </button>
          <button className="button" onClick={() => onUsePosition('player')}>
            My position
          </button>
          <button className="button" onClick={() => onUsePosition('waypoint')}>
            Waypoint
          </button>
        </div>
      )}

      <div className="button-row">
        <button className="button" onClick={onCopy}>
          Copy coords
        </button>
        <button className="button" onClick={onTeleport}>
          Teleport there
        </button>
      </div>
    </Section>
  );
}
