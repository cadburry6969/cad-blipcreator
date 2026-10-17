import type { Draft } from '../../draft';

/** Props every editor section receives */
export interface SectionProps {
  draft: Draft;
  readOnly: boolean;
  onUpdate: (patch: Partial<Draft>) => void;
}
