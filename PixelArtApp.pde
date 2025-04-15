CanvasGrid canvas;
int prevGridX;
int prevGridY;

void setup() {
  
  // This is completely arbitrary as this point
  // will need to add screen resizing later
  // static resolution changes would probably be best
  size(868, 868);
  
  // rows, cols, cellsize, xoffset, yoffset, gridlines, gridlinespacing
  // these will need to be abstracted to variables so they can be modified during runtime
  canvas = new CanvasGrid(256, 265, 2, 50, 50, true, 8);
}

void draw() {
  background(255);
  canvas.displayBackground(color(180), color(220));
  canvas.displayGrid();

}

void mousePressed() {
  
  // Stores the previous canvas state before the new brush stroke occurs
  canvas.storeChange();
  
  // Converting mouse position on screen to position within the canvas
  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);
  canvas.setPixel(x, y, color(0, 0, 255));
  
  prevGridX = x;
  prevGridY = y;
}

void mouseDragged() {
  
  // Converting mouse position on screen to position within the canvas
  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);

  drawLineBetween(prevGridX, prevGridY, x, y, color(0, 0, 255));
  //canvas.setPixel(x, y, color(0, 0, 255));
   
  prevGridX = x;
  prevGridY = y;
}

// Don't even ask me, I got this one entirely online (Bresenham's Line Alg)
// It works better than just calling setPixel during mouseDragged because
// it fills in every cell between two mouse positions whereas the former
// method relies on OS mouse events which results in some cells being skipped over
void drawLineBetween(int x0, int y0, int x1, int y1, color brushColor) {
  int dx = abs(x1 - x0);
  int dy = abs(y1 - y0);
  int sx = x0 < x1 ? 1 : -1;
  int sy = y0 < y1 ? 1 : -1;
  int err = dx - dy;

  while (true) {
    canvas.setPixel(x0, y0, brushColor);
    if (x0 == x1 && y0 == y1) break;
    int e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x0 += sx;
    }
    if (e2 < dx) {
      err += dx;
      y0 += sy;
    }
  }
}

void keyPressed() {
  if (key == 'z') {
    canvas.undoChange();
  }
}
