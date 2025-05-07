import java.util.ArrayList;

CanvasGrid canvas;
Palette palette;
int prevGridX;
int prevGridY;
color currentColor;

//global buttons
Button btn, btn2;

void setup() {
  
  // This is completely arbitrary as this point
  // will need to add screen resizing later
  // static resolution changes would probably be best
  size(868, 868);
  
  btn = new Button(600, 50, 80, 20 , "Undo", color(100, 100, 100), 20);
  btn2 = new Button(685, 50, 80, 20, "Cursor: Arrow", color(100, 100, 100),20);
  
  // rows, cols, cellsize, xoffset, yoffset, gridlines, gridlinespacing
  // these will need to be abstracted to variables so they can be modified during runtime
  
  canvas = new CanvasGrid(128, 128, 4, 50, 50, true, 8);
  
  palette = new Palette(color(0,0,0), 600, 200);
}

void draw() {
  background(255);
  //undo change if clicked - for some reason, I have to hold my left mouse button longer than you'd think for it to pop, but it does undo a change, holding it undoes many changes in order
    if(btn.isClicked()){
      canvas.undoChange();
      
    }
    
  //need for every button created
  btn.update();
  btn.display();
  btn2.update();
  btn2.display();
  
  canvas.displayBackground(color(180), color(220));
  canvas.displayGrid();
  
  palette.displayPalette();


}

void mousePressed() {
  
  if (palette.paletteClicked(mouseX, mouseY)) {
    palette.selectColor(mouseX, mouseY);
    currentColor = palette.getCurrentColor();
    return;
  }
  
  // Converting mouse position on screen to position within the canvas
  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);
  
  // Stores the previous canvas state before the new brush stroke occurs
  // Only stores change if the mouse press is within the bounds of the canvas
  if (canvas.isInBounds(x, y)) {
    canvas.storeChange();
  }
  
  canvas.setPixel(x, y, currentColor);
  
  prevGridX = x;
  prevGridY = y;

}

void mouseDragged() {
  
  // Converting mouse position on screen to position within the canvas
  int x = canvas.screenToGridX(mouseX);
  int y = canvas.screenToGridY(mouseY);

  drawLineBetween(prevGridX, prevGridY, x, y, currentColor);
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
  //change mouse to cross
  if (key == 'q'){
    btn2.label = "Cursor: Cross";
    cursor(CROSS);
  }
  //change mouse back to normal
  if (key == 'n'){
   btn2.label = "Cursor: Arrow";  
   cursor(ARROW);
  }
}
