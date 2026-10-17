import { Field } from '../ui/Field';
import { NumberInput } from '../ui/NumberInput';
import { Section } from '../ui/Section';
import { Toggle } from '../ui/Toggle';
import type { SectionProps } from './sections';

export function LegendSection({ draft, readOnly, onUpdate }: SectionProps) {
  const enabled = draft.category != null;

  return (
    <Section
      title="Map legend group"
      action={
        <Toggle
          label="Put it in a legend group"
          hideLabel
          checked={enabled}
          disabled={readOnly}
          onChange={(on) => onUpdate({ category: on ? 12 : null })}
        />
      }
    >
      {enabled && (
        <>
          <Field label="Group number" hint="Use 12 or higher for your own groups">
            <NumberInput
              value={draft.category ?? 12}
              disabled={readOnly}
              onChange={(category) => onUpdate({ category: Math.round(category) })}
            />
          </Field>
          <Field label="Group name">
            <input
              className="input"
              maxLength={32}
              placeholder="Shown in the pause map legend"
              value={draft.categoryLabel}
              disabled={readOnly}
              onChange={(e) => onUpdate({ categoryLabel: e.target.value })}
            />
          </Field>
        </>
      )}
    </Section>
  );
}
