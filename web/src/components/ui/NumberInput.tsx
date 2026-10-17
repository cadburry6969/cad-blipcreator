import { useEffect, useState } from 'react';

interface NumberInputProps {
  value: number;
  step?: number;
  disabled?: boolean;
  onChange: (value: number) => void;
}

/** Keeps the typed text while it isn't a valid number yet (e.g. "-" or "12.") */
export function NumberInput({ value, step = 1, disabled, onChange }: NumberInputProps) {
  const [text, setText] = useState(String(value));

  useEffect(() => {
    if (Number(text) !== value) setText(String(value));
  }, [value]);

  return (
    <input
      className="input"
      type="number"
      step={step}
      value={text}
      disabled={disabled}
      onChange={(e) => {
        setText(e.target.value);

        const parsed = Number(e.target.value);
        if (e.target.value.trim() !== '' && Number.isFinite(parsed)) onChange(parsed);
      }}
    />
  );
}
