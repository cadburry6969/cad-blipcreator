import type { IconOption } from '../../types';
import { Section } from '../ui/Section';
import { Slider } from '../ui/Slider';
import type { SectionProps } from './sections';

interface IconSectionProps extends SectionProps {
  icons: IconOption[];
  onPickIcon: () => void;
}

export function IconSection({ draft, readOnly, icons, onUpdate, onPickIcon }: IconSectionProps) {
  const icon = draft.icon ? icons.find((option) => option.name === draft.icon) : undefined;

  return (
    <Section title="Custom icon">
      <button className="pick" disabled={readOnly} onClick={onPickIcon}>
        {icon ? <img src={icon.url} alt="" /> : <span className="pick__swatch pick__swatch--empty" />}
        <span className="pick__text">
          <span className="field__label">Icon</span>
          <span>{draft.icon ?? 'None, uses the GTA sprite'}</span>
        </span>
      </button>

      {draft.icon && (
        <>
          <Slider
            label="Icon size"
            value={draft.iconSize}
            min={8}
            max={128}
            disabled={readOnly}
            format={(value) => `${value}px`}
            onChange={(iconSize) => onUpdate({ iconSize })}
          />
          <p className="muted">The sprite and colour above are still used where the icon can't be drawn.</p>
        </>
      )}
    </Section>
  );
}
