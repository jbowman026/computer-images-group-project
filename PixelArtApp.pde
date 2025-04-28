CanvasGrid canvas;
int prevGridX;
int prevGridY;

//global buttons
myButton btnUndo, btnCursor, btnSave, btnLoad;
int cursorMode = ARROW; //can be ARROW, CROSS, or other cursor types
boolean lockDrawing = false; //this is for some bs where it would draw a line to the undo button when clicked, still not fixed
String defaultSavePath; //this is so it defaults to downloads

void setup() {
  // This is completely arbitrary as this point
  // will need to add screen resizing later
  // static resolution changes would probably be best
  size(868, 868);
  defaultSavePath = getDownloadsPath();
  btnUndo = new myButton(600, 50, 80, 30, "Undo");
  btnCursor = new myButton(690, 50, 120, 30, "Cursor: Arrow");
  btnSave = new myButton(600, 90, 80, 30, "Save");
  btnLoad = new myButton(690, 90, 80, 30, "Load");
  
  // rows, cols, cellsize, xoffset, yoffset, gridlines, gridlinespacing
  // these will need to be abstracted to variables so they can be modified during runtime
  
  canvas = new CanvasGrid(256, 256, 2, 50, 50, true, 8);
}

void draw() {
  background(255);
  
  //reset all button states every frame
  btnUndo.wasPressed = mousePressed; //had to do this or else some bullshit was happening where buttons where
  btnCursor.wasPressed = mousePressed; //triggering while mouse was pressed down and drawing.
  btnSave.wasPressed = mousePressed;
  btnLoad.wasPressed = mousePressed;
  
  //display buttons
  btnUndo.display();
  btnCursor.display();
  btnSave.display();
  btnLoad.display();
  
  canvas.displayBackground(color(180), color(220));
  canvas.displayGrid();

}

String getDownloadsPath() { //had to find this online in order to find the downloads path
  String os = System.getProperty("os.name").toLowerCase(); //this is the simplest solution without getting additional libraries
  String home = System.getProperty("user.home");
  
  if (os.contains("win")) {
    return home + "\\Downloads\\";
  } else if (os.contains("mac")) {
    return home + "/Downloads/";
  } else { // Linux/Unix
    return home + "/Downloads/";
  }
}

void saveDrawing() {
  String timestamp = nf(year(),4) + nf(month(),2) + nf(day(),2) + "_" + nf(hour(),2) + nf(minute(),2); //gets timestamp
  String defaultName = "pixelart_" + timestamp + ".png"; //for creating a default name
  
  selectOutput("Save PNG:", "saveImageCallback", 
    new File(defaultSavePath + defaultName)); //opens the file diolog at default save path with generated file name
}

void saveImageCallback(File selection) { //instructions for the save operation
  if (selection == null) return; //exit if user canceled dialog
  
  String path = selection.getAbsolutePath(); //get absolute path of the file
  
  if (!path.toLowerCase().endsWith(".png")) { //force .png extension 
    path += ".png";
    selection = new File(path);
  }
  
  PImage img = createCanvasImage(); //create the image
  img.save(path); //save to path and print comfortaion to console
  println("Saved to Downloads: " + path);
}

PImage createCanvasImage() { //creates pimage copy of the canvas with transparency 
  //create ARGB image to support transparency
  PImage img = createImage(canvas.cols, canvas.rows, ARGB);
  
  img.loadPixels(); //gets the pixels 
  for (int y = 0; y < canvas.rows; y++) {
    for (int x = 0; x < canvas.cols; x++) {
      color c = canvas.getPixel(x, y);
      //preserve alpha channel if exists
      img.pixels[y * canvas.cols + x] = c; //sets pixels to the pimage
    }
  }
  img.updatePixels(); //finalize changes
  return img; //this is the image we are saving
}

void loadDrawing() { //opens the dialog
  //get Downloads path (works on Windows 10/11)
  String downloadsPath = System.getProperty("user.home") + "\\Downloads\\";
  
  // create a dummy file reference to force the dialog location
  File dummy = new File(downloadsPath + "dummy.pde"); // Using .pde as safe extension
  try { dummy.createNewFile(); } catch (Exception e) { /* Ignore */ }
  
  //open dialog - will start in Downloads because of dummy file
  selectInput("Load PNG Image:", "handleImageUpload", dummy); //this is the only way i got this to work
  
  //clean up dummy file (runs in background)
  dummy.delete();
}

void handleImageUpload(File selection) {
  if (selection == null) return;
  
  //load image with ARGB format to preserve alpha channel
  PImage img = loadImage(selection.getAbsolutePath());
  if (img == null) return;
  
  //convert to ARGB if not already
  if (img.format != ARGB) {
    PImage temp = createImage(img.width, img.height, ARGB);
    temp.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
    img = temp;
  }
  
  //apply to canvas with transparency
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      color pixel = img.get(x, y);
      //only draw non-transparent pixels
      if (alpha(pixel) > 0) {
        canvas.setPixel(x, y, pixel);
      }
    }
  }
  println("Loaded: " + selection.getName()); //console confirmation for debugging
}

// Update your mousePressed() to handle cursor button
void mousePressed() {
  //store button states FIRST, this is to avoid some bugs I was running into
  boolean undoClicked = btnUndo.isClicked();
  boolean cursorClicked = btnCursor.isClicked();
  boolean saveClicked = btnSave.isClicked();
  boolean loadClicked = btnLoad.isClicked();

  // Handle buttons (will exit if any button was pressed)
  if (undoClicked) {
    canvas.undoChange();
    return; 
  }
  if (cursorClicked) {
    toggleCursorMode();
    return;
  }
  if (saveClicked) {
    saveDrawing();
    return;
  }
  if (loadClicked) {
    loadDrawing();
    return;
  }

  // ONLY allow drawing if NO buttons were clicked
  canvas.storeChange();
  int x = canvas.screenToGridX(mouseX); //potential solution the stray line bug but it doesnt work 
  int y = canvas.screenToGridY(mouseY);
  canvas.setPixel(x, y, color(0, 0, 255));
  prevGridX = x;
  prevGridY = y;
}

void mouseDragged() {
  if (!lockDrawing) {
    int x = canvas.screenToGridX(mouseX);
    int y = canvas.screenToGridY(mouseY);
    drawLineBetween(prevGridX, prevGridY, x, y, color(0, 0, 255));
    prevGridX = x;
    prevGridY = y;
  }
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
  // Undo with Z (case insensitive)
  if (key == 'z' || key == 'Z') {
    canvas.undoChange();
    return;
  }

  // Toggle cursor mode between cross and arrow
  if (key == 'q' || key == 'Q') {
    toggleCursorMode();
    return;
  }
  
  // Quick save/load shortcuts
  if (key == 's' || key == 'S') {
    saveDrawing();
    return;
  }
  
  if (key == 'l' || key == 'L') {
    loadDrawing();
    return;
  }
}

// Toggle cursor mode and update button label
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