interface ToggleProps {
  /** text next to the switch, or only read by screen readers when `hideLabel` is set */
  label: string;
  hideLabel?: boolean;
  checked: boolean;
  disabled?: boolean;
  onChange: (checked: boolean) => void;
}

export function Toggle({ label, hideLabel, checked, disabled, onChange }: ToggleProps) {
  return (
    <label className={`toggle${disabled ? ' toggle--disabled' : ''}`}>
      <input
        type="checkbox"
        aria-label={label}
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
      />
      <span className="toggle__track" aria-hidden />
      {!hideLabel && <span className="toggle__label">{label}</span>}
    </label>
  );
}
