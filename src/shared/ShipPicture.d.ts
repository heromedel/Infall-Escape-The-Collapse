/**
 * What the window needs to draw one ship, and nothing the window shouldn't know. The host builds it from a
 * ShipDefinition (src/host/ShipPicture.ts); the window draws it (src/window/ShipDrawing.ts). Types only, shared
 * by both sides, so this file has no code.
 *
 * All positions are in ship pixels: 35 a tile, tile column 0 and row 0 at the ship's top-left tile. GDD 5G's
 * signed coordinates are already converted; Point centering leaves no gap.
 */

export interface ShipPicture {
  name: string;
  race: string;
  tileSize: number;
  columns: number;
  rows: number;
  /** The colour of this ship's powered systems and symbols on screen (GDD 14D). */
  powerColour: string;
  floorTiles: PictureTile[];
  rooms: PictureRoom[];
  /** Wall segments between a room tile and anything that is not the same room. */
  walls: PictureSegment[];
  doors: PictureDoor[];
  systems: PictureSystem[];
  conduits: PictureConduit[];
  crew: PictureCrew[];
  hullArt?: PictureArt;
}

export interface PictureTile {
  column: number;
  row: number;
  /** The signed ship coordinates (GDD 5G) the simulation uses, for orders. */
  x: number;
  y: number;
  roomId: number;
}

export interface PictureRoom {
  id: number;
  column: number;
  row: number;
  width: number;
  height: number;
}

export interface PictureSegment {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
}

export interface PictureDoor {
  id: number;
  /** The door's rectangle, centred on its wall. */
  x: number;
  y: number;
  width: number;
  height: number;
  /** A door facing space (GDD 5D). */
  airlock: boolean;
}

export interface PictureSystem {
  key: string;
  name: string;
  level: number;
  column: number;
  row: number;
  /** The wall the console sits against, if any. */
  wall?: 'North' | 'South' | 'East' | 'West';
  /** The system's standard symbol as SVG text (content/systems), or nothing: the window then draws a lettered square. */
  symbolSvg?: string;
}

export interface PictureConduit {
  column: number;
  row: number;
  runs: ('North' | 'South' | 'East' | 'West')[];
}

export interface PictureCrew {
  race: string;
  shape: 'Square' | 'Cross' | 'Triangle' | 'Star' | 'Diamond' | 'Crescent' | 'Circle' | 'QuestionMark';
  colour: string;
  column: number;
  row: number;
}

/** Hull art, sent whole so the window needs no file access: an SVG's text, or a PNG as a data URL. */
export interface PictureArt {
  kind: 'svg' | 'png';
  content: string;
  width: number;
  height: number;
  /** Where the tile grid's top-left corner sits inside the art, in art pixels. */
  gridX: number;
  gridY: number;
}
