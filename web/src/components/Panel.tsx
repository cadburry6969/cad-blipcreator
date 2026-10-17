import type { ReactNode } from 'react';

interface PanelProps {
  title: string;
  subtitle?: string;
  onBack?: () => void;
  onClose: () => void;
  children: ReactNode;
}

export function Panel({ title, subtitle, onBack, onClose, children }: PanelProps) {
  return (
    <div className="panel">
      <header className="panel__header">
        {onBack && (
          <button className="icon-button" onClick={onBack} aria-label="Back">
            ←
          </button>
        )}
        <div className="panel__titles">
          <h1>{title}</h1>
          {subtitle && <span className="muted">{subtitle}</span>}
        </div>
        <button className="icon-button" onClick={onClose} aria-label="Close editor">
          ✕
        </button>
      </header>
      {children}
    </div>
  );
}
