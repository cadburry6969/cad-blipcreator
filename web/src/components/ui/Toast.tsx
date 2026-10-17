export interface ToastMessage {
  id: number;
  type: 'success' | 'error';
  text: string;
}

interface ToastsProps {
  toasts: ToastMessage[];
}

export function Toasts({ toasts }: ToastsProps) {
  return (
    <div className="toasts">
      {toasts.map((toast) => (
        <div key={toast.id} className={`toast toast--${toast.type}`}>
          {toast.text}
        </div>
      ))}
    </div>
  );
}
