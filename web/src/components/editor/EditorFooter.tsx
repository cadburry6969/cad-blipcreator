import { useState } from 'react';

interface EditorFooterProps {
  canDelete: boolean;
  canSave: boolean;
  busy: boolean;
  onDelete: () => void;
  onViewMap: () => void;
  onSave: () => void;
}

export function EditorFooter({ canDelete, canSave, busy, onDelete, onViewMap, onSave }: EditorFooterProps) {
  const [confirming, setConfirming] = useState(false);

  return (
    <footer className="footer">
      {canDelete && (
        <button
          className={`button ${confirming ? 'button--danger' : 'button--ghost'}`}
          disabled={busy}
          onClick={() => (confirming ? onDelete() : setConfirming(true))}
          onBlur={() => setConfirming(false)}
        >
          {confirming ? 'Click again to delete' : 'Delete'}
        </button>
      )}

      <span className="footer__spacer" />

      <button className="button" onClick={onViewMap}>
        View on map
      </button>

      {canSave && (
        <button className="button button--primary" disabled={busy} onClick={onSave}>
          {busy ? 'Saving...' : 'Save'}
        </button>
      )}
    </footer>
  );
}
