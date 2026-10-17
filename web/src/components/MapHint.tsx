interface MapHintProps {
  text: string;
}

/** Shown at the top of the screen while the editor is hidden for the pause map */
export function MapHint({ text }: MapHintProps) {
  return <div className="map-hint">{text}</div>;
}
