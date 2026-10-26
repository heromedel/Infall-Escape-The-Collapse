/**
 * Pans and zooms the view over the drawing (GDD 3C): drag to pan, wheel to zoom about the pointer. Ship size
 * is never changed to fit; the camera moves instead. The zoom clamp setting (GDD 2D) comes later.
 */

export class Camera {
  private x = 0;
  private y = 0;
  private zoom = 1;
  /** Called after every move or zoom with the zoom, for things drawn at screen scale over the battle. */
  onChange?: (zoom: number) => void;

  constructor(private readonly viewport: SVGSVGElement, private readonly moved: SVGGElement) {
    this.listenForDragAndWheel();
    this.apply();
  }

  /** Puts the middle of a drawing of this size in the middle of the viewport, at zoom 1. */
  centreOn(width: number, height: number): void {
    const box = this.viewport.getBoundingClientRect();
    this.zoom = 1;
    this.x = (box.width - width) / 2;
    this.y = (box.height - height) / 2;
    this.apply();
  }

  /**
   * Zooms out just enough to show a drawing of this size whole, centred, with a margin. `reservedBottom` is
   * screen space under the drawing kept clear (a ship panel drawn at screen scale).
   */
  fitTo(width: number, height: number, reservedBottom = 0): void {
    const box = this.viewport.getBoundingClientRect();
    const margin = 24;
    this.zoom = Math.min(1.5, (box.width - 2 * margin) / width, (box.height - 2 * margin - reservedBottom) / height);
    this.x = (box.width - width * this.zoom) / 2;
    this.y = (box.height - reservedBottom - height * this.zoom) / 2;
    this.apply();
  }

  get currentZoom(): number {
    return this.zoom;
  }

  /** Drag pans; a drag of more than a few pixels swallows the click that would follow, so panning never orders. */
  private listenForDragAndWheel(): void {
    let dragging = false;
    let moved = 0;
    let lastX = 0;
    let lastY = 0;
    this.viewport.addEventListener('pointerdown', (event) => {
      if (event.button !== 0 && event.button !== 1) return;
      dragging = true; moved = 0; lastX = event.clientX; lastY = event.clientY;
      this.viewport.setPointerCapture(event.pointerId);
    });
    this.viewport.addEventListener('pointermove', (event) => {
      if (!dragging) return;
      moved += Math.abs(event.clientX - lastX) + Math.abs(event.clientY - lastY);
      if (moved > 4) this.viewport.classList.add('panning');
      this.x += event.clientX - lastX;
      this.y += event.clientY - lastY;
      lastX = event.clientX; lastY = event.clientY;
      this.apply();
    });
    this.viewport.addEventListener('pointerup', () => { dragging = false; });
    this.viewport.addEventListener('click', (event) => {
      const panned = moved > 4;
      moved = 0;
      this.viewport.classList.remove('panning');
      if (panned) event.stopImmediatePropagation();
    }, { capture: true });
    this.viewport.addEventListener('wheel', (event) => {
      event.preventDefault();
      const factor = event.deltaY < 0 ? 1.15 : 1 / 1.15;
      const box = this.viewport.getBoundingClientRect();
      const pointerX = event.clientX - box.left;
      const pointerY = event.clientY - box.top;
      // Zoom about the pointer: the ship point under it stays under it.
      this.x = pointerX - (pointerX - this.x) * factor;
      this.y = pointerY - (pointerY - this.y) * factor;
      this.zoom *= factor;
      this.apply();
    }, { passive: false });
  }

  private apply(): void {
    this.moved.setAttribute('transform', `translate(${this.x} ${this.y}) scale(${this.zoom})`);
    this.onChange?.(this.zoom);
  }
}
