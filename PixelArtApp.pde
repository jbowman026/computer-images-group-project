import java.util.ArrayList;
import java.io.File;

CanvasGrid canvas;
Palette palette;
int prevGridX;
int prevGridY;
color currentColor;

// global buttons
myButton btnUndo, btnCursor, btnSave, btnLoad;
int cursorMode = ARROW; // can be ARROW, CROSS, or other cursor types
boolean lockDrawing = false; // prevents stray lines when interacting with UI
String defaultSavePath;       // defaults to Downloads

void setup() {
  size(868, 868); // TODO: make this dynamic
  defaultSavePath = getDownloadsPath();

  // buttons
  btnUndo   = new myButton(600, 50,  80, 30, "Undo");
  btnCursor = new myButton(690, 50, 120, 30, "Cursor: Arrow");
  btnSave   = new myButton(600, 90,  80, 30, "Save");
  btnLoad   = new myButton(690, 90,  80, 30, "Load");

  // rows, cols, cell size, x offset, y offset, showGrid, gridSpacing
  canvas = new CanvasGrid(128, 128, 4, 50, 50, true, 8);

  palette = new Palette(color(0, 0, 0), 600, 200);
  currentColor = palette.getCurrentColor();
}

void draw() {
  background(255);

  // reset press state each frame
  btnUndo.wasPressed   = mousePressed;
  btnCursor.wasPressed = mousePressed;
  btnSave.wasPressed   = mousePressed;
  btnLoad.wasPressed   = mousePressed;

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
  // palette selection first
  if (palette.paletteClicked(mouseX, mouseY)) {
    palette.selectColor(mouseX, mouseY);
    currentColor = palette.getCurrentColor();
    lockDrawing = true; // ignore subsequent drag
    return;
  }

  // buttons
  boolean undoClicked   = btnUndo.isClicked();
  boolean cursorClicked = btnCursor.isClicked();
  boolean saveClicked   = btnSave.isClicked();
  boolean loadClicked   = btnLoad.isClicked();

  if (undoClicked) {
    canvas.undoChange();
    lockDrawing = true;
    return;
  }
  if (cursorClicked) {
    toggleCursorMode();
    lockDrawing = true;
    return;
  }
  if (saveClicked) {
    saveDrawing();
    lockDrawing = true;
    return;
  }
  if (loadClicked) {
    loadDrawing();
    lockDrawing = true;
    return;
  }

  // drawing
  lockDrawing = false;

  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);

  if (canvas.isInBounds(x, y)) {
    canvas.storeChange();
    canvas.setPixel(x, y, currentColor);
    prevGridX = x;
    prevGridY = y;
  }
}

void mouseDragged() {
  if (lockDrawing) return;

  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);

  drawLineBetween(prevGridX, prevGridY, x, y, currentColor);

  prevGridX = x;
  prevGridY = y;
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

void keyPressed() {
  if (key == 'z' || key == 'Z') { canvas.undoChange(); return; }
  if (key == 'q' || key == 'Q') { toggleCursorMode(); return; }
  if (key == 's' || key == 'S') { saveDrawing(); return; }
  if (key == 'l' || key == 'L') { loadDrawing(); return; }
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

String getDownloadsPath() {
  String os = System.getProperty("os.name").toLowerCase();
  String home = System.getProperty("user.home");

  if (os.contains("win")) {
    return home + "\\Downloads\\";
  } else if (os.contains("mac")) {
    return home + "/Downloads/";
  } else {
    return home + "/Downloads/";
  }
}

void saveDrawing() {
  String timestamp = nf(year(),4) + nf(month(),2) + nf(day(),2) + "_" +
                     nf(hour(),2) + nf(minute(),2);
  String defaultName = "pixelart_" + timestamp + ".png";

  selectOutput("Save PNG:", "saveImageCallback",
               new File(defaultSavePath + defaultName));
}

void saveImageCallback(File selection) {
  if (selection == null) return;

  String path = selection.getAbsolutePath();
  if (!path.toLowerCase().endsWith(".png")) {
    path += ".png";
    selection = new File(path);
  }

  PImage img = createCanvasImage();
  img.save(path);
  println("Saved to: " + path);
}

PImage createCanvasImage() {
  PImage img = createImage(canvas.cols, canvas.rows, ARGB);
  img.loadPixels();
  for (int y = 0; y < canvas.rows; y++) {
    for (int x = 0; x < canvas.cols; x++) {
      color c = canvas.getPixel(x, y);
      img.pixels[y * canvas.cols + x] = c;
    }
  }
  img.updatePixels();
  return img;
}

void loadDrawing() {
  String downloadsPath = System.getProperty("user.home") + "\\Downloads\\";
  File dummy = new File(downloadsPath + "dummy.pde");
  try { dummy.createNewFile(); } catch (Exception e) { }
  selectInput("Load PNG Image:", "handleImageUpload", dummy);
  dummy.delete();
}

void handleImageUpload(File selection) {
  if (selection == null) return;

  PImage img = loadImage(selection.getAbsolutePath());
  if (img == null) return;

  if (img.format != ARGB) {
    PImage temp = createImage(img.width, img.height, ARGB);
    temp.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
    img = temp;
  }

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      color pixel = img.get(x, y);
      if (alpha(pixel) > 0) {
        canvas.setPixel(x, y, pixel);
      }
    }
  }
  println("Loaded: " + selection.getName());
}
