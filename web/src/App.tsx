import { useCallback, useEffect, useState } from 'react';
import { BlipEditor, type EditTarget } from './components/editor/BlipEditor';
import { BlipList } from './components/list/BlipList';
import { MapHint } from './components/MapHint';
import { Panel } from './components/Panel';
import type { IconActions } from './components/pickers/IconPicker';
import { Toasts } from './components/ui/Toast';
import { type Draft, draftFromBlip, draftToBlip, newDraft } from './draft';
import { useNuiMessage } from './hooks/useNuiMessage';
import { useToasts } from './hooks/useToasts';
import { mockOpenPayload } from './nui/mock';
import { fetchNui, isBrowser } from './nui/fetchNui';
import { parseIconMutation, parseMutation } from './nui/parse';
import type { EditorBlip, IconOption, OpenPayload } from './types';

type View = { kind: 'list' } | { kind: 'edit'; target: EditTarget; initial: Draft };

const TITLES: Record<EditTarget['kind'], string> = {
  new: 'New blip',
  saved: 'Edit blip',
  script: 'Script blip',
};

export function App() {
  const [open, setOpen] = useState(isBrowser);
  /** set while the editor is hidden for the pause map, with an optional hint to show */
  const [hidden, setHidden] = useState<{ hint: string | null } | null>(null);
  const [payload, setPayload] = useState<OpenPayload>(mockOpenPayload);
  const [view, setView] = useState<View>({ kind: 'list' });
  const [busy, setBusy] = useState(false);
  const { toasts, push } = useToasts();

  const setBlips = (blips: EditorBlip[]) => setPayload((current) => ({ ...current, blips }));
  const setIcons = (icons: IconOption[]) => setPayload((current) => ({ ...current, icons }));

  useNuiMessage((message) => {
    switch (message.action) {
      case 'open':
        setPayload(message.data);
        setView({ kind: 'list' });
        setHidden(null);
        setOpen(true);
        break;
      case 'close':
        setOpen(false);
        break;
      case 'hide':
        setHidden({ hint: message.hint });
        break;
      case 'show':
        setHidden(null);
        break;
      default: {
        const _exhaustive: never = message;
        return _exhaustive;
      }
    }
  });

  const close = useCallback(() => {
    setOpen(false);
    void fetchNui('close');
  }, []);

  const backToList = useCallback(() => setView({ kind: 'list' }), []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape' || !open) return;

      if (view.kind === 'edit') backToList();
      else close();
    };

    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, view.kind, backToList, close]);

  const openBlip = (blip: EditorBlip) => {
    const target: EditTarget = blip.saved
      ? { kind: 'saved', id: blip.id }
      : { kind: 'script', id: blip.id, owner: blip.owner };

    setView({ kind: 'edit', target, initial: draftFromBlip(blip.data, payload.player) });
  };

  const save = async (target: EditTarget, draft: Draft) => {
    setBusy(true);

    const id = target.kind === 'saved' ? target.id : undefined;
    const { result, blips } = parseMutation(await fetchNui('save', { id, blip: draftToBlip(draft) }));

    setBusy(false);
    if (blips) setBlips(blips);

    if (result?.ok) {
      push('success', `Saved "${draft.label.trim()}"`);
      backToList();
    } else {
      push('error', result?.error ?? 'Saving failed');
    }
  };

  const remove = async (id: string) => {
    setBusy(true);

    const { result, blips } = parseMutation(await fetchNui('delete', { id }));

    setBusy(false);
    if (blips) setBlips(blips);

    if (result?.ok) {
      push('success', 'Blip deleted');
      backToList();
    } else {
      push('error', result?.error ?? 'Deleting failed');
    }
  };

  const iconActions: IconActions = {
    add: async (name, url) => {
      const { result, icons } = parseIconMutation(await fetchNui('addIcon', { name, url }));

      if (icons) setIcons(icons);
      if (!result?.ok) return result?.error ?? 'Adding the icon failed';

      push('success', `Added icon "${name}"`);
      return null;
    },
    remove: async (name) => {
      const { result, icons } = parseIconMutation(await fetchNui('removeIcon', { name }));

      if (icons) setIcons(icons);
      if (!result?.ok) {
        const problem = result?.error ?? 'Removing the icon failed';
        push('error', problem);
        return problem;
      }

      push('success', `Removed icon "${name}"`);
      return null;
    },
  };

  if (!open) return null;

  const savedCount = payload.blips.filter((blip) => blip.saved).length;

  // the editor stays mounted while hidden for the pause map, so the draft isn't lost
  return (
    <>
      {hidden?.hint && <MapHint text={hidden.hint} />}
      <div className="app" hidden={hidden !== null}>
        {view.kind === 'list' ? (
          <Panel title="Blip Editor" subtitle={`${savedCount} saved blips`} onClose={close}>
            <BlipList
              blips={payload.blips}
              icons={payload.icons}
              permissions={payload.permissions}
              onOpen={openBlip}
              onCreate={() => setView({ kind: 'edit', target: { kind: 'new' }, initial: newDraft(payload.player) })}
            />
          </Panel>
        ) : (
          <Panel title={TITLES[view.target.kind]} onBack={backToList} onClose={close}>
            <BlipEditor
              key={view.target.kind === 'new' ? 'new' : view.target.id}
              target={view.target}
              initial={view.initial}
              icons={payload.icons}
              permissions={payload.permissions}
              iconActions={iconActions}
              busy={busy}
              onSave={(draft) => void save(view.target, draft)}
              onDelete={(id) => void remove(id)}
              onToast={push}
            />
          </Panel>
        )}
        <Toasts toasts={toasts} />
      </div>
    </>
  );
}
