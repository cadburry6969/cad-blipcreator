import type { PermissionOption } from '../../types';
import { Field } from '../ui/Field';
import { Section } from '../ui/Section';
import type { SectionProps } from './sections';

interface GeneralSectionProps extends SectionProps {
  permissions: PermissionOption[];
}

export function GeneralSection({ draft, readOnly, permissions, onUpdate }: GeneralSectionProps) {
  const known = permissions.some((permission) => permission.value === draft.permissions);

  return (
    <Section title="General">
      <Field label="Name">
        <input
          className="input"
          maxLength={64}
          value={draft.label}
          disabled={readOnly}
          onChange={(e) => onUpdate({ label: e.target.value })}
        />
      </Field>

      <Field label="Who can see it" hint={known ? undefined : 'This permission is not in config.lua, add it there to save'}>
        <select
          className="input"
          value={draft.permissions}
          disabled={readOnly}
          onChange={(e) => onUpdate({ permissions: e.target.value })}
        >
          {permissions.map((permission) => (
            <option key={permission.value} value={permission.value}>
              {permission.label}
            </option>
          ))}
          {!known && <option value={draft.permissions}>{draft.permissions}</option>}
        </select>
      </Field>
    </Section>
  );
}
