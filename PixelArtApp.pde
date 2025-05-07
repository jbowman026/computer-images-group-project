import java.util.ArrayList;
import java.io.File;

CanvasGrid canvas;
Palette palette;
FileManager fileManager;
int prevGridX;
int prevGridY;
color currentColor;

// global buttons
Button btnUndo, btnCursor, btnSave, btnLoad;
int cursorMode = ARROW; // can be ARROW, CROSS, or other cursor types
boolean lockDrawing = false; // prevents stray lines when interacting with UI
String defaultSavePath;       // defaults to Downloads

void setup() {
  size(868, 868); // TODO: make this dynamic
  
  canvas = new CanvasGrid(64, 64, 8, 50, 50, true, 8);
  palette = new Palette(color(0, 0, 0), 600, 200);
  fileManager = new FileManager(this, canvas, palette); 
  
  defaultSavePath = fileManager.getDownloadsPath();

  // buttons
  btnUndo   = new Button(600, 50,  80, 30, "Undo");
  btnCursor = new Button(690, 50, 120, 30, "Cursor: Arrow");
  btnSave   = new Button(600, 90,  80, 30, "Save");
  btnLoad   = new Button(690, 90,  80, 30, "Load");
}

void draw() {
  background(255);

  // draw UI
  btnUndo.display();
  btnCursor.display();
  btnSave.display();
  btnLoad.display();

  canvas.displayBackground(color(180), color(220));
  canvas.displayGrid();
  palette.displayPalette();
}

/* ---------- Mouse & keyboard ---------- */

void mousePressed() {
  
  // if the palette is selected
  if (palette.paletteClicked(mouseX, mouseY)) {
    palette.selectColor(mouseX, mouseY);
    currentColor = palette.getCurrentColor();
    lockDrawing = true; // ignore subsequent drag
    return;
  }
  
  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);
  
  // if the canvas is selected
  if (canvas.isInBounds(x, y)) {
    canvas.storeChange();
    canvas.setPixel(x, y, currentColor);
    prevGridX = x;
    prevGridY = y;
  }
  
  btnUndo.mousePressed();
  btnCursor.mousePressed();
  btnSave.mousePressed();
  btnLoad.mousePressed();
  
  // drawing
  lockDrawing = false;
}

void mouseDragged() {
  if (lockDrawing) return;

  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);

  drawLineBetween(prevGridX, prevGridY, x, y, currentColor);

  prevGridX = x;
  prevGridY = y;
}

void mouseReleased() {
  // react only when a full click is completed
  if (btnUndo.mouseReleased())   { canvas.undoChange(); lockDrawing = true; }
  if (btnCursor.mouseReleased()) { toggleCursorMode();  lockDrawing = true; }
  if (btnSave.mouseReleased())   { fileManager.saveDrawing();               lockDrawing = true; }
  if (btnLoad.mouseReleased())   { canvas.storeChange(); fileManager.loadDrawing(); lockDrawing = true; }

  /* palette / canvas release logic (if any) */
}

void keyPressed() {
  if (key == 'z' || key == 'Z') { canvas.undoChange(); return; }
  if (key == 'q' || key == 'Q') { toggleCursorMode(); return; }
  if (key == 's' || key == 'S') {fileManager.saveDrawing(); return; }
  if (key == 'l' || key == 'L') { fileManager.loadDrawing(); return; }
}

void toggleCursorMode() {
  if (cursorMode == ARROW) {
    cursorMode = CROSS;
    btnCursor.label = "Cursor: Cross";
    cursor(CROSS);
  } else {
    cursorMode = ARROW;
    btnCursor.label = "Cursor: Arrow";
    cursor(ARROW);
  }
}

// Bresenham's line algorithm
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

// ----  NEW: public callbacks that Processing can see  ----
public void saveImageCallback(File f) {
  println("[wrapper] got file =", f);
  fileManager.saveImageCallback(f);   // just relay to helper
}

public void handleImageUpload(File f) {
  fileManager.handleImageUpload(f);   // just relay to helper
}
