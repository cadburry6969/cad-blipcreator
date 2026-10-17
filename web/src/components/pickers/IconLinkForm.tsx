import { useState } from 'react';

interface IconLinkFormProps {
  /** returns an error message, or null when the icon was added */
  onAdd: (name: string, url: string) => Promise<string | null>;
}

const LINK_PATTERN = /^https:\/\/\S+\.(png|svg|jpe?g|webp)(\?\S*)?$/i;

/** 'https://site.com/icons/Police-Car.svg' becomes 'police_car' */
export function nameFromUrl(url: string) {
  const file = url.split(/[?#]/)[0]?.split('/').pop() ?? '';

  return file
    .replace(/\.[^.]+$/, '')
    .toLowerCase()
    .replace(/[^a-z0-9_]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 32);
}

export function IconLinkForm({ onAdd }: IconLinkFormProps) {
  const [url, setUrl] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const finalName = name.trim() || nameFromUrl(url.trim());
  const validLink = LINK_PATTERN.test(url.trim());

  const submit = async () => {
    if (!validLink) {
      setError('Use an https:// link ending in .png, .svg, .jpg or .webp');
      return;
    }

    if (!finalName) {
      setError('Give the icon a name');
      return;
    }

    setBusy(true);
    const problem = await onAdd(finalName, url.trim());
    setBusy(false);

    setError(problem);

    if (!problem) {
      setUrl('');
      setName('');
    }
  };

  return (
    <div className="link-form">
      <span className="field__label">Add an icon from a link</span>
      <div className="link-form__row">
        <input
          className="input"
          placeholder="https://example.com/icon.png"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
        />
        <input
          className="input link-form__name"
          placeholder={nameFromUrl(url) || 'name'}
          maxLength={32}
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <button className="button button--primary" disabled={busy || !url.trim()} onClick={() => void submit()}>
          {busy ? 'Adding...' : 'Add'}
        </button>
      </div>
      {validLink && <img className="link-form__preview" src={url.trim()} alt="" />}
      {error && <span className="field__hint">{error}</span>}
    </div>
  );
}
