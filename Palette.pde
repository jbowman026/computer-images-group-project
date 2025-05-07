class Palette {
  
  // array of colors that make up the palette
  int[] colors;
  // how many slots in the palette are being used
  int count;  
  // The color that is currently selected
  int currentColor;
  // where to draw the palette
  int offsetX, offsetY;    
  
  int columns = 8;
  
  int swatchSize = 25;

  Palette(int defaultColor, int x, int y) {
    this.count = 0;
    this.currentColor = defaultColor;
    this.offsetX = x;
    this.offsetY = y;
    
    colors = new int[1];
    
    addColor(color(0, 0, 0));
    addColor(color(255, 0, 0));
    addColor(color(0, 255, 0));
    addColor(color(0, 0, 255));
    addColor(color(255, 255, 0));
    addColor(color(255, 0, 255));
    addColor(color(0, 255, 255));
    addColor(color(255, 255, 255));
  }

  // adds a new color to the palette
  void addColor(int c) {
    
    // Don't add a color if it already appears in the palette
    for (int i = 0; i < colors.length; i++) {
      if (colors[i] == c) {
        return;
      }
    }
    
    // Create a larger array if the amount of colors outgrows the current size
    if (count >= colors.length) {
      int[] bigger = new int[colors.length * 2];
      System.arraycopy(colors, 0, bigger, 0, colors.length);
      colors = bigger;
    }
    
    // add the color
    colors[count++] = c;
  }

  int getColor(int idx) {
    if (idx >= 0 && idx < count) {
      return colors[idx];
    }
    return currentColor;  // fallback
  }

  int size() {
    return count;
  }

  void setCurrentColor(int c) {
    currentColor = c;
  }

  int getCurrentColor() {
    return currentColor;
  }

  void displayPalette() { //<>//
    
    for (int i = 0; i < count; i++) {
      
        int x = i % columns;
        int y = i / columns;
        
        fill(colors[i]);
        stroke(0);
        rect(offsetX + x*swatchSize, offsetY + y*swatchSize, swatchSize, swatchSize);
        
    }
  } //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//

  void selectColor(float mx, float my) {
    
    for (int i = 0; i < count; i++) {
      int col = i % columns;
      int row = i / columns;
      
      float x = offsetX + col * swatchSize;
      float y = offsetY + row * swatchSize;
  
      if (mx >= x && mx < x + swatchSize &&
          my >= y && my < y + swatchSize) {
        currentColor = colors[i];
        break;
      }
    }
  }
  
  boolean paletteClicked(int mx, int my) {
    
  int rows = (count + columns - 1) / columns;  
  int w = columns * swatchSize;
  int h = rows * swatchSize;
  
  return mx >= palette.offsetX
      && mx <= palette.offsetX + w
      && my >= palette.offsetY
      && my <= palette.offsetY + h;
  }
}
