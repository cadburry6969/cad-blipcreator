import { getColour } from '../../data';
import { Field } from '../ui/Field';
import { NumberInput } from '../ui/NumberInput';
import { Section } from '../ui/Section';
import { Slider } from '../ui/Slider';
import { Toggle } from '../ui/Toggle';
import type { SectionProps } from './sections';

interface AreaSectionProps extends SectionProps {
  onPickColour: () => void;
}

export function AreaSection({ draft, readOnly, onUpdate, onPickColour }: AreaSectionProps) {
  const colourId = draft.radiusColour ?? draft.colour;
  const colour = getColour(colourId);
  const enabled = draft.radius != null;

  return (
    <Section
      title="Area circle"
      action={
        <Toggle
          label="Show an area circle"
          hideLabel
          checked={enabled}
          disabled={readOnly}
          onChange={(on) => onUpdate({ radius: on ? 100 : null })}
        />
      }
    >
      {enabled && (
        <>
          <Field label="Radius (metres)">
            <NumberInput
              value={draft.radius ?? 100}
              disabled={readOnly}
              onChange={(radius) => onUpdate({ radius })}
            />
          </Field>

          <button className="pick" disabled={readOnly} onClick={onPickColour}>
            <span className="pick__swatch" style={{ background: colour?.hex ?? '#ffffff' }} />
            <span className="pick__text">
              <span className="field__label">Area colour</span>
              <span>{draft.radiusColour == null ? 'Same as blip' : `${colourId} · ${colour?.name ?? ''}`}</span>
            </span>
          </button>

          <Slider
            label="Area opacity"
            value={draft.radiusAlpha}
            min={0}
            max={255}
            disabled={readOnly}
            format={(value) => `${Math.round((value / 255) * 100)}%`}
            onChange={(radiusAlpha) => onUpdate({ radiusAlpha })}
          />
        </>
      )}
    </Section>
  );
}
