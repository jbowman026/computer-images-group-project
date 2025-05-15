import javax.swing.JColorChooser;

class Palette {
  
  // array of colors that make up the palette
  int[] colors;
  // how many slots in the palette are being used
  int count;  
  // The color that is currently selected
  int currentColor;
  // where to draw the palette
  int offsetX, offsetY;    
  // number of columns in the pallete
  int columns = 7;
  // size of each color
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

  void displayPalette() {
    // because we're including the "add color" swatch
    int total = count + 1;  
    
    // logic for drawing each swatch
    for (int i = 0; i < total; i++) {
      int col = i % columns;
      int row = i / columns;
      int x   = offsetX + col * swatchSize;
      int y   = offsetY + row * swatchSize;

      // always draws the "add color" swatch at the end of the rest
      if (i < count) {
        fill(colors[i]);
        stroke(0);
        rect(x, y, swatchSize, swatchSize);
      } else {
        fill(200);
        stroke(0);
        rect(x, y, swatchSize, swatchSize);
        fill(0);
        textAlign(CENTER, CENTER);
        text("+", x + swatchSize/2, y + swatchSize/2);
      }
    }
  } //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
  
  // logic to make sure the correct color is selected
  void selectColor(float mx, float my) {
    int total = count + 1;
    for (int i = 0; i < total; i++) {
      int col = i % columns;
      int row = i / columns;
      float x = offsetX + col * swatchSize;
      float y = offsetY + row * swatchSize;

      if (mx >= x && mx < x + swatchSize
       && my >= y && my < y + swatchSize) {
        if (i < count) {
          currentColor = colors[i];
        } else {
          // add new color
          int picked = showColorChooser();
          if (picked != currentColor) {
            addColor(picked);
            currentColor = picked;
          }
        }
        break;
      }
    }
  }
  
  boolean paletteClicked(int mx, int my) {
    int totalRows = ((count + 1) + columns - 1) / columns;
    int w = columns   * swatchSize;
    int h = totalRows * swatchSize;
    return mx >= offsetX
        && mx <  offsetX + w
        && my >= offsetY
        && my <  offsetY + h;
  }
  
  // Pops up a Swing color chooser and returns the selected color
  private int showColorChooser() {
    java.awt.Color awt = JColorChooser.showDialog(
      null,
      "Pick a new palette color",
      new java.awt.Color(
        (currentColor >> 16) & 0xFF,
        (currentColor >>  8) & 0xFF,
        (currentColor      ) & 0xFF
      )
    );
    if (awt != null) {
      return color(awt.getRed(), awt.getGreen(), awt.getBlue());
    }
    return currentColor;
  }
}
