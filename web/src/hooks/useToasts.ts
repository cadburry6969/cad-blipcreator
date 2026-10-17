import { useCallback, useState } from 'react';
import type { ToastMessage } from '../components/ui/Toast';

const TOAST_MS = 3500;

export function useToasts() {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const push = useCallback((type: ToastMessage['type'], text: string) => {
    const id = Date.now() + Math.random();

    setToasts((current) => [...current, { id, type, text }]);
    window.setTimeout(() => setToasts((current) => current.filter((toast) => toast.id !== id)), TOAST_MS);
  }, []);

  return { toasts, push };
}
