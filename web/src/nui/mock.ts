// Fake game responses so the UI can be developed in a normal browser (npm run dev)

import type { EditorBlip, OpenPayload } from '../types';

let blips: EditorBlip[] = [
  {
    id: '1698163614',
    saved: true,
    owner: 'cad-blipcreator',
    data: {
      label: 'Legion Square',
      coords: { x: 197.24, y: -935.72, z: 30.69 },
      sprite: 77,
      colour: 3,
      scale: 1,
      alpha: 255,
      display: 2,
      shortRange: true,
      permissions: 'none',
    },
  },
  {
    id: 'blip_1_1',
    saved: true,
    owner: 'cad-blipcreator',
    data: {
      label: 'Mission Row PD',
      coords: { x: 441.0, y: -982.0, z: 30.7 },
      sprite: 60,
      colour: 29,
      scale: 0.9,
      alpha: 255,
      display: 2,
      shortRange: true,
      permissions: 'police',
      icon: 'example_png',
      iconSize: 24,
    },
  },
  {
    id: 'blip_1_2',
    saved: false,
    owner: 'cad-garages',
    data: {
      label: 'Unit 12',
      coords: { x: 100, y: -500, z: 30 },
      sprite: 56,
      colour: 3,
      scale: 1,
      alpha: 255,
      display: 2,
      shortRange: false,
      permissions: 'none',
      player: 1,
    },
  },
];

export const mockOpenPayload: OpenPayload = {
  blips,
  icons: [
    { name: 'example_png', url: 'https://docs-backend.fivem.net/blips/radar_police_station.png', link: false },
    { name: 'example_svg', url: 'https://docs-backend.fivem.net/blips/radar_hospital.png', link: false },
  ],
  permissions: [
    { label: 'Everyone', value: 'none' },
    { label: 'Police', value: 'police' },
  ],
  player: { x: 200, y: -900, z: 30 },
};

let seq = 10;

export function mockNui(event: string, body: unknown): unknown {
  const request = (body ?? {}) as { id?: string; blip?: EditorBlip['data'] };

  switch (event) {
    case 'save': {
      if (!request.blip) return { result: { ok: false, error: 'missing blip' }, blips };

      const id = request.id ?? `blip_mock_${seq++}`;
      const saved: EditorBlip = { id, saved: true, owner: 'cad-blipcreator', data: request.blip };

      blips = [...blips.filter((blip) => blip.id !== id), saved];

      return { result: { ok: true, id }, blips };
    }
    case 'delete':
      blips = blips.filter((blip) => blip.id !== request.id);
      return { result: { ok: true, id: request.id }, blips };
    case 'refresh':
      return blips;
    case 'position':
      return { x: 215.5, y: -810.2, z: 30.7 };
    case 'pickOnMap':
      return { x: -1037.42, y: -2737.81, z: 20.17 };
    case 'addIcon': {
      const icon = body as { name: string; url: string };
      mockOpenPayload.icons = [...mockOpenPayload.icons.filter((i) => i.name !== icon.name), { ...icon, link: true }];
      return { result: { ok: true, id: icon.name }, icons: mockOpenPayload.icons };
    }
    case 'removeIcon': {
      const { name } = body as { name: string };
      mockOpenPayload.icons = mockOpenPayload.icons.filter((i) => i.name !== name);
      return { result: { ok: true, id: name }, icons: mockOpenPayload.icons };
    }
    default:
      return true;
  }
}
