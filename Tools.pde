// enums for the various tool types
enum ToolType { BRUSH, LINE, ERASE, FILL, PICKER }

// Interface for a common set of methods shared by all tools
interface Tool {
  void onPress (int gx, int gy);
  void onDrag  (int gx, int gy);
  void onRelease(int gx, int gy);
}

// Concrete classes of the Tool interface

// Brush tool is the default tool
class BrushTool implements Tool {
  
  color brushColour;
  BrushTool(color c) { brushColour = c; }

  // The brush object remembers the previous position during mouse movement
  public void onPress (int gx, int gy) { 
    canvas.setPixel(gx, gy, brushColour); 
    prevGridX = gx;
    prevGridY = gy;
  }
  // Uses Bresenham's line algorithm 
  public void onDrag  (int gx, int gy) { 
    drawLineBetween(prevGridX, prevGridY, gx, gy, brushColour); 
    prevGridX = gx;
    prevGridY = gy;
  }
  
  public void onRelease(int gx, int gy) {
    canvas.storeChange(); 
  }
}

// Erasure tool is just the brush tool with the color set to transparent
class EraserTool extends BrushTool {
  EraserTool() { super(color(255, 255, 255, 0)); }
}

class LineTool implements Tool {
  int sx = -1, sy = -1; // drag start
  color[][] backup = null; // temp copy for preview
  boolean drawing = false;

  public void onPress(int gx, int gy) {
    backup = canvas.clonePixels(); // temporary copy so we can see the line without changing the real canvas's pixel values
    sx = gx; sy = gy;
    drawing = true;
  }

  public void onDrag(int gx, int gy) {
    if (!drawing) return;
    canvas.setPixels(backup); // restore state so that unnessary pixel changes are reverted
    drawLineBetween(sx, sy, gx, gy, currentColor);  // draw preview
  }

  public void onRelease(int gx, int gy) {
    if (!drawing) return;

    canvas.setPixels(backup); // restore again
    canvas.storeChange(); // actually store the change once the line is drawn
    drawLineBetween(sx, sy, gx, gy, currentColor);

    drawing = false;
    backup  = null;
  }
}

// Uses a flood fill algorithm to fill the canvas in with color
class FillTool implements Tool {
  public void onPress(int gx, int gy) {
    color target = canvas.getPixel(gx, gy);
    if (target == currentColor) return;
    floodFill(gx, gy, target, currentColor);
  }
  public void onDrag(int gx, int gy) {}
  
  public void onRelease(int gx, int gy) {
    canvas.storeChange();
  }
}

// Changes the current selected color
class PickerTool implements Tool {
  public void onPress(int gx, int gy) { currentColor = canvas.getPixel(gx, gy); }
  public void onDrag(int gx, int gy) {}
  public void onRelease(int gx, int gy) {}
}

// The tool manager class is for keeping track of tool state
class ToolManager {
  
  // brush is the default tool type on start up
  ToolType currentType = ToolType.BRUSH;
  
  // creating an instance of each tool class
  Tool brush = new BrushTool(currentColor);
  Tool eraser = new EraserTool();
  Tool line = new LineTool();
  Tool fill = new FillTool();
  Tool picker = new PickerTool();

  // updates current type when a new tool is selected
  void setTool(ToolType t) {
    currentType = t;
    if (t == ToolType.BRUSH) ((BrushTool)brush).brushColour = currentColor;
  }
  
  // handler that gives us back which tool is currently selected
  Tool current() {
    switch (currentType) {
      case ERASE:  return eraser;
      case LINE:   return line;
      case FILL:   return fill;
      case PICKER: return picker;
      default:     return brush;
    }
  }
}

// Flood fill algorithm for the bucket tool
void floodFill(int sx, int sy, color target, color replacement) {
  if (target == replacement) return;

  IntList stackX = new IntList();
  IntList stackY = new IntList();
  stackX.append(sx);
  stackY.append(sy);

  while (stackX.size() > 0) {
    int x = stackX.remove(stackX.size()-1);
    int y = stackY.remove(stackY.size()-1);

    if (!canvas.isInBounds(x, y)) continue;
    if (canvas.getPixel(x, y) != target) continue;

    canvas.setPixel(x, y, replacement);

    stackX.append(x+1); stackY.append(y);
    stackX.append(x-1); stackY.append(y);
    stackX.append(x);   stackY.append(y+1);
    stackX.append(x);   stackY.append(y-1);
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
