import { DISPLAY_OPTIONS, getColour, getSprite, spriteLabel } from '../../data';
import { Field } from '../ui/Field';
import { Section } from '../ui/Section';
import { Slider } from '../ui/Slider';
import { Toggle } from '../ui/Toggle';
import type { SectionProps } from './sections';

interface AppearanceSectionProps extends SectionProps {
  onPickSprite: () => void;
  onPickColour: () => void;
}

export function AppearanceSection({ draft, readOnly, onUpdate, onPickSprite, onPickColour }: AppearanceSectionProps) {
  const sprite = getSprite(draft.sprite);
  const colour = getColour(draft.colour);
  const knownDisplay = DISPLAY_OPTIONS.some((option) => option.value === draft.display);

  return (
    <Section title="Appearance">
      <div className="pick-row">
        <button className="pick" disabled={readOnly} onClick={onPickSprite}>
          {sprite ? <img src={sprite.url} alt="" /> : <span className="pick__swatch" />}
          <span className="pick__text">
            <span className="field__label">Sprite</span>
            <span>{sprite ? `${draft.sprite} · ${spriteLabel(sprite)}` : draft.sprite}</span>
          </span>
        </button>

        <button className="pick" disabled={readOnly} onClick={onPickColour}>
          <span className="pick__swatch" style={{ background: colour?.hex ?? '#ffffff' }} />
          <span className="pick__text">
            <span className="field__label">Colour</span>
            <span>{colour ? `${draft.colour} · ${colour.name}` : draft.colour}</span>
          </span>
        </button>
      </div>

      <Slider
        label="Size"
        value={draft.scale}
        min={0.1}
        max={3}
        step={0.05}
        disabled={readOnly}
        format={(value) => `${Math.round(value * 100)}%`}
        onChange={(scale) => onUpdate({ scale })}
      />

      <Slider
        label="Opacity"
        value={draft.alpha}
        min={0}
        max={255}
        disabled={readOnly}
        format={(value) => `${Math.round((value / 255) * 100)}%`}
        onChange={(alpha) => onUpdate({ alpha })}
      />

      <Field label="Shows on">
        <select
          className="input"
          value={draft.display}
          disabled={readOnly}
          onChange={(e) => onUpdate({ display: Number(e.target.value) })}
        >
          {DISPLAY_OPTIONS.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
          {!knownDisplay && <option value={draft.display}>Custom ({draft.display})</option>}
        </select>
      </Field>

      <div className="toggle-row">
        <Toggle
          label="Only show when nearby"
          checked={draft.shortRange}
          disabled={readOnly}
          onChange={(shortRange) => onUpdate({ shortRange })}
        />
        <Toggle label="Flash" checked={draft.flash} disabled={readOnly} onChange={(flash) => onUpdate({ flash })} />
      </div>
    </Section>
  );
}
