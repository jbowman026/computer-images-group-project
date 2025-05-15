import java.util.Stack;

// class for the canvas and all of it's associated properties
class CanvasGrid {
  
  // Declaring variables for number of rows and columns in the grid,
  // the size of each cell in the grid,
  // the color of each grid cell,
  // and the width and height of the canvas
  int rows, cols;
  int cellSize;
  color[][] pixels;
  int pixelWidth, pixelHeight;
  
  //These are stacks of 2d arrays of color type that will hold brush stroke history and undo history respectively
  Stack<color[][]> changeHistory;
  Stack<color[][]> undoHistory;
  
  // Variables to define how far from the left and top of the screen the grid is
  int gridOffsetX; 
  int gridOffsetY;
  
  // Whether we add gridlines to the canvas or not and what their spacing should be
  boolean isGridLines;
  int gridLineSpacing;
  
  // Constructor function
  CanvasGrid(int cols, int rows, int cellSize, 
  int gridOffsetX, int gridOffsetY,
  boolean isGridLines, int gridLineSpacing) {
    this.cols = cols;
    this.rows = rows;
    this.cellSize = cellSize;
    this.gridOffsetX = gridOffsetX;
    this.gridOffsetY = gridOffsetY;
    this.isGridLines = isGridLines;
    this.gridLineSpacing = gridLineSpacing;
    
    pixels = new color[cols][rows];
    changeHistory = new Stack<color[][]>();
    undoHistory = new Stack<color[][]>();  
    
    // initializing pixels as transparent
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        pixels[x][y] = color(255, 255, 255, 0);
      }
    }
    // This will never be popped
    changeHistory.push(clonePixels());
    
    pixelWidth  = cols * cellSize;
    pixelHeight = rows * cellSize;
  }
  
  // Methods to set and get pixel colors
  void setPixel(int x, int y, color c) {
    if (isInBounds(x, y)) {
      pixels[x][y] = c;
    }
  }
  
  color getPixel(int x, int y) {
    if (isInBounds(x, y)) {
      return pixels[x][y];
    }
    return color(0); // Default for out of bounds
  }
  
  void setDensity(int newCols, int newRows) {
    // update cols/rows
    cols = newCols;
    rows = newRows;
  
    // pick the biggest square cell that still fits the original area
    cellSize = min(pixelWidth / cols, pixelHeight / rows);
  
    // rebuild the pixel array to match the new dimensions
    pixels = new color[cols][rows];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        pixels[x][y] = color(255,255,255,0);
      }
    }
    // Recenter the canvas in the case of images with different aspect ratios
    recenter();
  }
    
  // Boolean to define if a mouse click is within the bounds of the grid
  boolean isInBounds(int x, int y) {
    if(x >= 0 && x < cols && y >= 0 && y < rows) {
      return true;
    } else {
      return false;
    }
  }
  
  // Displays the canvas
  void displayGrid() {
    
    // Creating the grid
    noStroke();
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        fill(pixels[x][y]);
        rect(x * cellSize + gridOffsetX, y * cellSize + gridOffsetY, cellSize, cellSize);
      }
    }
    
    // Creating the grid lines if they're enabled
    if(isGridLines) {
        stroke(0, 0, 0);
        strokeWeight(1);
        for (int y = 0; y <= rows; y += gridLineSpacing) {
          line(gridOffsetX, y * cellSize + gridOffsetY, cols * cellSize + gridOffsetX, y * cellSize + gridOffsetY);
        }
        for (int x = 0; x <= cols; x += gridLineSpacing) {
          line(x * cellSize + gridOffsetX, gridOffsetY, x * cellSize + gridOffsetX, rows * cellSize + gridOffsetY);
        }
    }
  }
  
  void displayBackground(color c1, color c2) {
    
    // Logic to make a checkerboard pattern for the background of the canvas
    for (int y = 0; y < rows * 2; y++) {
      for (int x = 0; x < cols * 2; x++) {

        if ((x + y) % 2 == 0) {
          fill(c1);
        } else {
          fill(c2);
        }
        noStroke();
        rect(x * cellSize/2.0 + gridOffsetX, y * cellSize/2.0 + gridOffsetY, cellSize/2.0, cellSize/2.0);
      }
    }
  }
  
  // Converts screen coordinates to grid coordinates
  int screenToGridX(float screenX) {
    return floor((screenX - gridOffsetX) / cellSize);
  }

  int screenToGridY(float screenY) {
    return floor((screenY - gridOffsetY) / cellSize);
  }
  
  void undoChange() {
    if (changeHistory.size() > 1) { // keep the earliest snapshot
      color[][] current = changeHistory.pop(); // remove curent frame
      undoHistory.push(current); // save it for redo
  
      setPixels(changeHistory.peek()); // draw the new top
    }
  }
  
  void redoChange() {
    if (!undoHistory.isEmpty()) {
      color[][] redo = undoHistory.pop(); // take next redo frame
      changeHistory.push(redo); // put it back on main stack
      setPixels(redo); // draw it
    }
  }
  
  // store a copy of the most recent change and clear redo
  void storeChange() {
    changeHistory.push(clonePixels()); // clone current pixels
    undoHistory.clear(); // invalidate redo chain
  }
  
  // creates a perfect copy of the current canvas state
  color[][] clonePixels() {
    color[][] cp = new color[cols][rows];
    for (int x = 0; x < cols; x++) {
      arrayCopy(pixels[x], cp[x]); 
    }
    return cp;
  }

  // replaces the whole pixel array
  void setPixels(color[][] src) {
    for (int x = 0; x < cols; x++) {
      arrayCopy(src[x], pixels[x]);
    }
  }
  
  void recenter() {
    gridOffsetX = (width  - cols*cellSize) / 2;
    gridOffsetY = (height - rows*cellSize) / 2;
  }
}
