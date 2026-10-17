import { useEffect, useRef } from 'react';
import { parseMessage } from '../nui/parse';
import type { NuiMessage } from '../types';

/** Calls the handler for every valid message sent with SendNUIMessage */
export function useNuiMessage(handler: (message: NuiMessage) => void) {
  const handlerRef = useRef(handler);
  handlerRef.current = handler;

  useEffect(() => {
    const listener = (event: MessageEvent<unknown>) => {
      const message = parseMessage(event.data);
      if (message) handlerRef.current(message);
    };

    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, []);
}
