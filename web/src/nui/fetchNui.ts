import { mockNui } from './mock';

declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

/** True when running in a normal browser instead of the game */
export const isBrowser = typeof window.GetParentResourceName !== 'function';

const resourceName = window.GetParentResourceName?.() ?? 'cad-blipcreator';

/**
 * Calls a RegisterNUICallback handler in client/editor.lua.
 * The reply is unknown until a parser in parse.ts checks it.
 */
export async function fetchNui(event: string, body: unknown = {}): Promise<unknown> {
  if (isBrowser) return mockNui(event, body);

  const response = await fetch(`https://${resourceName}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(body),
  });

  return response.json();
}
