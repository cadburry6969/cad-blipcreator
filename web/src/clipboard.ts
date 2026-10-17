import type { Vec3 } from './types';

export const formatVec3 = ({ x, y, z }: Vec3) => `vector3(${x.toFixed(2)}, ${y.toFixed(2)}, ${z.toFixed(2)})`;

/** The game's browser blocks navigator.clipboard, so this copies through a hidden text box */
export function copyText(text: string): boolean {
  const box = document.createElement('textarea');

  box.value = text;
  box.style.position = 'fixed';
  box.style.opacity = '0';
  document.body.appendChild(box);
  box.select();

  const copied = document.execCommand('copy');
  box.remove();

  return copied;
}
