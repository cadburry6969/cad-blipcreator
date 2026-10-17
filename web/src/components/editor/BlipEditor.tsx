import { useEffect, useState } from 'react';
import { copyText, formatVec3 } from '../../clipboard';
import { type Draft, draftToBlip, validateDraft } from '../../draft';
import { fetchNui } from '../../nui/fetchNui';
import { parseVec3 } from '../../nui/parse';
import type { IconOption, PermissionOption, PositionSource } from '../../types';
import { ColourPicker } from '../pickers/ColourPicker';
import { type IconActions, IconPicker } from '../pickers/IconPicker';
import { SpritePicker } from '../pickers/SpritePicker';
import { AppearanceSection } from './AppearanceSection';
import { AreaSection } from './AreaSection';
import { EditorFooter } from './EditorFooter';
import { GeneralSection } from './GeneralSection';
import { IconSection } from './IconSection';
import { LegendSection } from './LegendSection';
import { PositionSection } from './PositionSection';

/** new = not saved yet, saved = editable, script = made by another resource, read only */
export type EditTarget = { kind: 'new' } | { kind: 'saved'; id: string } | { kind: 'script'; id: string; owner: string };

type Picker = 'sprite' | 'colour' | 'radiusColour' | 'icon' | null;

interface BlipEditorProps {
  target: EditTarget;
  initial: Draft;
  icons: IconOption[];
  permissions: PermissionOption[];
  iconActions: IconActions;
  busy: boolean;
  onSave: (draft: Draft) => void;
  onDelete: (id: string) => void;
  onToast: (type: 'success' | 'error', text: string) => void;
}

const PREVIEW_DELAY = 150;

export function BlipEditor({
  target,
  initial,
  icons,
  permissions,
  iconActions,
  busy,
  onSave,
  onDelete,
  onToast,
}: BlipEditorProps) {
  const [draft, setDraft] = useState(initial);
  const [picker, setPicker] = useState<Picker>(null);
  const readOnly = target.kind === 'script';
  const editingId = target.kind === 'saved' ? target.id : undefined;

  const update = (patch: Partial<Draft>) => setDraft((current) => ({ ...current, ...patch }));

  // live preview on the map while editing, removed when the editor closes
  useEffect(() => {
    if (readOnly) return;

    const timer = window.setTimeout(() => {
      void fetchNui('preview', { id: editingId, blip: draftToBlip(draft) });
    }, PREVIEW_DELAY);

    return () => window.clearTimeout(timer);
  }, [draft, editingId, readOnly]);

  useEffect(() => () => void fetchNui('preview', { blip: null }), []);

  const usePosition = async (source: PositionSource) => {
    const coords = parseVec3(await fetchNui('position', { source }));

    if (coords) update({ coords });
    else onToast('error', source === 'waypoint' ? 'Set a waypoint on the map first' : 'Could not get your position');
  };

  const pickOnMap = async () => {
    const coords = parseVec3(await fetchNui('pickOnMap', { z: draft.coords.z }));

    if (!coords) {
      onToast('error', 'No point picked');
      return;
    }

    update({ coords });
    onToast('success', `Picked ${formatVec3(coords)}`);
  };

  const copyCoords = () => {
    const text = formatVec3(draft.coords);

    if (copyText(text)) onToast('success', `Copied ${text}`);
    else onToast('error', 'Could not copy, the coordinates are shown above');
  };

  const save = () => {
    const problem = validateDraft(draft);

    if (problem) onToast('error', problem);
    else onSave(draft);
  };

  const sectionProps = { draft, readOnly, onUpdate: update };

  return (
    <div className="editor">
      <div className="editor__scroll">
        {target.kind === 'script' && (
          <p className="notice">
            Made by <strong>{target.owner}</strong>. Script blips can't be edited here.
          </p>
        )}

        <GeneralSection {...sectionProps} permissions={permissions} />
        <PositionSection
          {...sectionProps}
          onUsePosition={(source) => void usePosition(source)}
          onPickOnMap={() => void pickOnMap()}
          onCopy={copyCoords}
          onTeleport={() => void fetchNui('teleport', { coords: draft.coords })}
        />
        <AppearanceSection
          {...sectionProps}
          onPickSprite={() => setPicker('sprite')}
          onPickColour={() => setPicker('colour')}
        />
        <IconSection {...sectionProps} icons={icons} onPickIcon={() => setPicker('icon')} />
        <AreaSection {...sectionProps} onPickColour={() => setPicker('radiusColour')} />
        <LegendSection {...sectionProps} />
      </div>

      <EditorFooter
        canDelete={target.kind === 'saved'}
        canSave={!readOnly}
        busy={busy}
        onDelete={() => editingId && onDelete(editingId)}
        onViewMap={() => void fetchNui('viewMap')}
        onSave={save}
      />

      {picker === 'sprite' && (
        <SpritePicker
          value={draft.sprite}
          onClose={() => setPicker(null)}
          onPick={(sprite) => {
            update({ sprite });
            setPicker(null);
          }}
        />
      )}

      {(picker === 'colour' || picker === 'radiusColour') && (
        <ColourPicker
          title={picker === 'colour' ? 'Choose a colour' : 'Choose the area colour'}
          value={picker === 'colour' ? draft.colour : draft.radiusColour}
          onClose={() => setPicker(null)}
          onPick={(colour) => {
            update(picker === 'colour' ? { colour } : { radiusColour: colour });
            setPicker(null);
          }}
        />
      )}

      {picker === 'icon' && (
        <IconPicker
          icons={icons}
          value={draft.icon}
          actions={iconActions}
          onClose={() => setPicker(null)}
          onPick={(icon) => {
            update({ icon });
            setPicker(null);
          }}
        />
      )}
    </div>
  );
}
