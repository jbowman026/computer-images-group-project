// CSC-545 Group Project
// Contributors: Jayden Bowman, Cooper Brown, Eric Morgan

import java.util.ArrayList;
import java.io.File;

CanvasGrid canvas;
Palette palette;
FileManager fileManager;
ToolManager toolManager;

int prevGridX;
int prevGridY;
color currentColor;

// global buttons
Button btnUndo, btnRedo, btnCursor, btnSave, btnLoad;
Button btnBrush, btnLine, btnErase, btnFill, btnPick;

int cursorMode = ARROW; // can be ARROW or CROSS
boolean lockDrawing = false; // prevents stray lines when interacting with UI
String defaultSavePath; // defaults to Downloads


void setup() {
  
  size(968, 868);

  // Setting up the canvas
  int cols = 64;
  int rows = 64;
  int desiredSz = 512; // canvas will be around 512*512 on screen
  int cellSize = min(desiredSz/cols, desiredSz/rows); // Canvas size remains constant with different pixel densities
  int canvasW = cols*cellSize;
  int canvasH = rows*cellSize;
  int gridX = (width  - canvasW)/2;
  int gridY = (height - canvasH)/2;

  // Initializing objects
  canvas = new CanvasGrid(cols, rows, cellSize, gridX, gridY, true, 8);
  palette = new Palette(color(0), 0, 0); // placeholder
  fileManager = new FileManager(this, canvas, palette);
  toolManager = new ToolManager();
  currentColor = palette.getCurrentColor();

  // Common spacing values
  int margin = 20;
  int gap    = 10;
  int btnH   = 30;

  // tool selection 
  int toolW = 120;
  int toolX = gridX - toolW - margin;
  int ty = gridY;
  btnBrush = new Button(toolX, ty, toolW, btnH, "Brush");
  btnLine = new Button(toolX, ty+=btnH+gap, toolW, btnH, "Line");
  btnErase = new Button(toolX, ty+=btnH+gap, toolW, btnH, "Erase");
  btnFill = new Button(toolX, ty+=btnH+gap, toolW, btnH, "Fill");
  btnPick = new Button(toolX, ty+=btnH+gap, toolW, btnH, "Picker");

  // commands and palette
  int cmdW = 80;
  int rightX = gridX + canvasW + margin;
  int rightX2 = rightX + cmdW + gap;
  int cy = gridY;

  // Undo / Redo
  btnUndo = new Button(rightX,  cy, cmdW, btnH, "Undo");
  btnRedo = new Button(rightX2, cy, cmdW, btnH, "Redo");

  // Save / Load
  cy += btnH + gap;
  btnSave = new Button(rightX, cy, cmdW, btnH, "Save");
  btnLoad = new Button(rightX2, cy, cmdW, btnH, "Load");

  // Cursor toggle
  cy += btnH + gap;
  btnCursor = new Button(rightX, cy, cmdW*2 + gap, btnH, "Cursor: Arrow");

  // Palette spacing
  palette.offsetX = rightX;
  palette.offsetY = cy + btnH + (2*gap);
}

void draw() {
  background(255);

  // display command buttons
  btnUndo.display();
  btnRedo.display();
  btnCursor.display();
  btnSave.display();
  btnLoad.display();
  
  // display tool buttons
  btnBrush.display();
  btnLine.display();
  btnErase.display();
  btnFill.display();
  btnPick.display();

  // display canvas and palette
  canvas.displayBackground(color(180), color(220));
  canvas.displayGrid();
  palette.displayPalette();
}

void mousePressed() {
  
  // handle button presses
  btnBrush.mousePressed();
  btnLine.mousePressed();
  btnErase.mousePressed();
  btnFill.mousePressed();
  btnPick.mousePressed();
  
  btnUndo.mousePressed();
  btnRedo.mousePressed();
  btnCursor.mousePressed();
  btnSave.mousePressed();
  btnLoad.mousePressed();
  
  // if the palette is selected
  if (palette.paletteClicked(mouseX, mouseY)) {
    palette.selectColor(mouseX, mouseY);
    currentColor = palette.getCurrentColor();
    toolManager.setTool(toolManager.currentType);
    lockDrawing = true; // ignore further drag
    return;
  }
  
  // Match the position of the click on screen to the pixel on the canvas
  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);
  
  // if the canvas is selected
  if (canvas.isInBounds(x, y)) {
    toolManager.current().onPress(x, y);
    prevGridX = x; prevGridY = y;
  }
  
  lockDrawing = false;
}

void mouseDragged() {
  
  if (lockDrawing) return;

  int gx = canvas.screenToGridX(mouseX);
  int gy = canvas.screenToGridY(mouseY);
  if (canvas.isInBounds(gx, gy)) {
    toolManager.current().onDrag(gx, gy);
  }
}

void mouseReleased() {
  // react only when a full click is completed
  if (btnUndo.mouseReleased())   { canvas.undoChange(); lockDrawing = true; }
  if (btnRedo.mouseReleased())   { canvas.redoChange(); lockDrawing = true; }
  if (btnCursor.mouseReleased()) { toggleCursorMode();  lockDrawing = true; }
  if (btnSave.mouseReleased())   { fileManager.saveDrawing(); lockDrawing = true; }
  if (btnLoad.mouseReleased())   { canvas.storeChange(); fileManager.loadDrawing(); lockDrawing = true; }
  
  if (btnBrush.mouseReleased()) toolManager.setTool(ToolType.BRUSH);
  if (btnLine .mouseReleased()) toolManager.setTool(ToolType.LINE);
  if (btnErase.mouseReleased()) toolManager.setTool(ToolType.ERASE);
  if (btnFill .mouseReleased()) toolManager.setTool(ToolType.FILL);
  if (btnPick .mouseReleased()) toolManager.setTool(ToolType.PICKER);
  
  int gx = canvas.screenToGridX(mouseX);
  int gy = canvas.screenToGridY(mouseY);
  if (canvas.isInBounds(gx, gy))
    toolManager.current().onRelease(gx, gy);
}

void keyPressed() {
  
  // using switch cases here because they're better
  switch (key) {
    // tools
    case 'b': case 'B': toolManager.setTool(ToolType.BRUSH); break;
    case 'i': case 'I': toolManager.setTool(ToolType.LINE); break; 
    case 'e': case 'E': toolManager.setTool(ToolType.ERASE); break;
    case 'f': case 'F': toolManager.setTool(ToolType.FILL); break;
    case 'p': case 'P': toolManager.setTool(ToolType.PICKER); break;

    // undo / redo
    case 'z': case 'Z': canvas.undoChange(); break;
    case 'y': case 'Y': canvas.redoChange(); break; 

    // save / load
    case 's': case 'S': fileManager.saveDrawing(); break;
    case 'l': case 'L': fileManager.loadDrawing(); break;

    // cursor toggle
    case 'c': case 'C': toggleCursorMode(); break;
  }
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

// public callbacks for the saving and uploading image functions
// so the main sketch can use them
public void saveImageCallback(File f) {
  println("[wrapper] got file =", f);
  fileManager.saveImageCallback(f);
}

public void handleImageUpload(File f) {
  fileManager.handleImageUpload(f);
}
