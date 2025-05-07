class Palette {
  
  // array of colors that make up the palette
  int[] colors;
  // how many slots in the palette are being used
  int count;  
  // The color that is currently selected
  int currentColor;
  // where to draw the palette
  int offsetX, offsetY;     
  
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

  // automatically grow the array when full
  void addColor(int c) {
    if (count >= colors.length) {
      int[] bigger = new int[colors.length * 2];
      System.arraycopy(colors, 0, bigger, 0, colors.length);
      colors = bigger;
    }
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

  void displayPalette() {
    for (int i = 0; i < count; i++) {
      fill(colors[i]);
      stroke(0);
      rect(offsetX, offsetY + i*swatchSize,
           swatchSize, swatchSize);
    }
  }

  void selectColor(float mx, float my) {
    for (int i = 0; i < count; i++) {
      float x = offsetX;
      float y = offsetY + i*swatchSize;
      if (mx >= x && mx <= x + swatchSize
       && my >= y && my <= y + swatchSize) {
        currentColor = colors[i];
        break; 
      }
    }
  }
  
  boolean paletteClicked(int mx, int my) {
  int w = palette.swatchSize;
  int h = palette.swatchSize * palette.size();
  return mx >= palette.offsetX
      && mx <= palette.offsetX + w
      && my >= palette.offsetY
      && my <= palette.offsetY + h;
  }
}
