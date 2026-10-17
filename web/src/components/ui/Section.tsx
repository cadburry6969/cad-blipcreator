import type { ReactNode } from 'react';

interface SectionProps {
  title: string;
  /** shown on the right of the title, e.g. a toggle that enables the section */
  action?: ReactNode;
  children?: ReactNode;
}

export function Section({ title, action, children }: SectionProps) {
  return (
    <section className="section">
      <header className="section__header">
        <h3 className="section__title">{title}</h3>
        {action}
      </header>
      {children && <div className="section__body">{children}</div>}
    </section>
  );
}
