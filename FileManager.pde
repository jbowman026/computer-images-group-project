// Class for handling file operations (loading images into the canvas and saving from the canvas)

class FileManager {
  
  PApplet parent; // handle to the main sketch
  CanvasGrid cg; // canvas that's being saved or loaded into
  Palette p;
  String defaultSavePath;

  FileManager(PApplet parent, CanvasGrid cg, Palette p) {
    this.parent = parent;
    this.cg = cg;
    this.p = p;
    defaultSavePath = getDownloadsPath();
  }

  // Generates a time-stamped default file name
  public void saveDrawing() {
    String timestamp   = nf(year(),4)+nf(month(),2)+nf(day(),2)+"_"+nf(hour(),2)+nf(minute(),2);
    String defaultName = "pixelart_" + timestamp + ".png";

    // takes the title in the dialog, callback (method name), and the callback object (the main sketch)
    parent.selectOutput("Save PNG:", "saveImageCallback", new File(defaultSavePath + defaultName), parent);
  }
  
  // Loads the image into the canvas
  public void loadDrawing() {
    File dummy = new File(defaultSavePath + "dummy.pde");
    try { dummy.createNewFile(); } catch (Exception ignored) {}
    parent.selectInput("Load PNG Image:", "handleImageUpload", dummy, parent);
    dummy.delete();
  }
  
  // Callbacks

  // Converts the CanvasGrid into a PImage and saves it to the chosen path
  void saveImageCallback(File selection) {
    println("[helper] selection =", selection);
    if (selection == null) return;
    
    
    int factor = promptUpscale();
    println("[helper] factor chosen =", factor);
    
    String path = selection.getAbsolutePath();
    if (!path.toLowerCase().endsWith(".png")) path += ".png";
    
    
    PImage upImg = upscaleCanvas(factor);
    upImg.save(path);
    
    println("Saved to: " + path);
  }
  
  // Modifies and loads the png that the user selects
  void handleImageUpload(File selection) {
    
    if (selection == null) return;
  
    // Load the image
    PImage img = parent.loadImage(selection.getAbsolutePath());
    if (img == null) return;
  
    // Convert to ARGB if needed
    if (img.format != ARGB) {
      PImage tempImg = parent.createImage(img.width, img.height, ARGB);
      tempImg.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
      img = tempImg;
    }
  
    // Ask the user how they want to scale the image to fit the canvas
    int[] ans = promptDownscale(img.width, img.height);
    if (ans[0] < 0) return;
  
    // Collecting user input
    int targetW = ans[0];
    int targetH = ans[1];  
    int paletteSize = ans[2];
    boolean lockAspect = ans[3] == 1;
  
    // preserve the aspect ratio if that's what the user wanted
    if (lockAspect) {
      float srcRatio = (float) img.width / img.height;
      float dstRatio = (float) targetW / targetH;
      if (srcRatio > dstRatio) {           // source wider than target
        targetH = round(targetW / srcRatio);
      } else {
        targetW = round(targetH * srcRatio);
      }
    }
    
    // The image is first resized and then quantized
    // Doing this in the reverse order yeilds a different effect which actually looks really good,
    // but it looks less like actual pixel art and it doesn't do as well with a low palette size
    img.resize(targetW, targetH);
    
    color[] imgPalette = new color[paletteSize];
    PImage qImg = quantize(img, paletteSize, imgPalette);
    
    // Resize the canvas to fit the image
    cg.setSize(targetW, targetH);
    
    // The resized and quantized image is painted onto the grid
    for (int y = 0; y < targetH && y < cg.rows; y++) {
      for (int x = 0; x < targetW && x < cg.cols; x++) {
        color px = qImg.get(x, y);
        if (parent.alpha(px) > 0) cg.setPixel(x, y, px);
      }
    }
    
    // Add the colors in the palette of the image to the palette of the program
    for(int i = 0; i < imgPalette.length; i++) { 
      p.addColor(imgPalette[i]);
    }
  
    println("Loaded: " + selection.getName() +
            " (" + img.width + "×" + img.height + " → " +
            targetW + "×" + targetH + ")");
  }

  // helper functions
  
  // Creates a GUI component that lets the user adjust the resolution and aspect ratio of the image they're loading in
  int[] promptDownscale(int currentW, int currentH) {
    
    // Build the Swing widgets
    
    // Three text fields for the width, height, and palette size
    javax.swing.JTextField wField = new javax.swing.JTextField("" + currentW, 5);
    javax.swing.JTextField hField = new javax.swing.JTextField("" + currentH, 5);
    javax.swing.JTextField pSField = new javax.swing.JTextField("" + currentH, 5);
    
    // Lock aspect checkbox (starts turned on)
    javax.swing.JCheckBox lockBox = new javax.swing.JCheckBox("Lock aspect", true);
  
    // This panel holds all of the components
    javax.swing.JPanel panel = new javax.swing.JPanel();
    panel.add(new javax.swing.JLabel("Width:"));
    panel.add(wField);
    panel.add(new javax.swing.JLabel("Height:"));
    panel.add(hField);
    panel.add(new javax.swing.JLabel("Palette Size:"));
    panel.add(pSField);
    panel.add(lockBox);
    
    // Live sync setup, keeps fields tied when aspect lock is on
    
    // Variable for original aspect ratio
    final float aspect = (float) currentW / currentH;
    
    final javax.swing.text.Document wDoc = wField.getDocument();
    final javax.swing.text.Document hDoc = hField.getDocument();
    
    final boolean[] guard = { false }; 
    
    // One DocumentListener instance used for both text fields
    javax.swing.event.DocumentListener docSync = new javax.swing.event.DocumentListener() {
      private void sync(javax.swing.JTextField src, javax.swing.JTextField dst, boolean wToH) {
        
        // Aborts if aspect lock is off
        if (!lockBox.isSelected() || guard[0]) return;
        
        // Logic to handle user input
        try {
          int v = Integer.parseInt(src.getText().trim());
          guard[0] = true;   
          int calc = wToH ? Math.round(v / aspect)  
                          : Math.round(v * aspect);
          dst.setText("" + calc);
        } catch (NumberFormatException ignored) {
        } finally {
          guard[0] = false;
        }
      }
      
      // Each text field call insert/removeUpdate on any change
      public void insertUpdate (javax.swing.event.DocumentEvent e){
        if (e.getDocument() == wDoc) sync(wField, hField, true);
        else                         sync(hField, wField, false);
      }
      public void removeUpdate  (javax.swing.event.DocumentEvent e){ insertUpdate(e); }
      public void changedUpdate (javax.swing.event.DocumentEvent e){}
    };
    
    // Attach listener to each fields underlying document
    wDoc.addDocumentListener(docSync);
    hDoc.addDocumentListener(docSync);
  
    // Show the dialog
    
    // Any component inside the sketch window
    java.awt.Component win = (java.awt.Component) parent.getSurface().getNative();
  
    int result = javax.swing.JOptionPane.showConfirmDialog(
        win,
        panel,
        "Scale image to fit grid",
        javax.swing.JOptionPane.OK_CANCEL_OPTION,
        javax.swing.JOptionPane.PLAIN_MESSAGE
    );
    
    // if user hits cancel or closes the dialog, singnal caller with -1s
    if (result != javax.swing.JOptionPane.OK_OPTION) return new int[] { -1, -1, -1, 0 };
  
    // Parse the final numbers and return them
  
    try {
      int w = Integer.parseInt(wField.getText().trim());
      int h = Integer.parseInt(hField.getText().trim());
      int pS = Integer.parseInt(pSField.getText().trim());
      
      if (w <= 0 || h <= 0 || pS < 2)
        throw new NumberFormatException();
      
      // return the width, height, palette size, and lock aspect status
      return new int[] { w, h, pS, lockBox.isSelected() ? 1 : 0 };
    } catch (NumberFormatException e) {

      javax.swing.JOptionPane.showMessageDialog(
          win,
          "Width and height must be integers.",
          "Invalid input",
          javax.swing.JOptionPane.ERROR_MESSAGE
      );
      
      // If the user cancel's or the dialog fails, just abort
      return new int[] { -1, -1, -1, 0 };
    }
  }
  
  // Writes each pixel into a flat PImage array and returns a fully formed ARGb image that mirrors the grid
  private PImage createCanvasImage() {
    PImage img = createImage(cg.cols, cg.rows, ARGB);
    img.loadPixels();
    for (int y = 0; y < cg.rows; y++) {
      for (int x = 0; x < cg.cols; x++) {
        img.pixels[y * cg.cols + x] = cg.getPixel(x, y);
      }
    }
    img.updatePixels();
    return img;
  }
  
  // Uses k-means clustering to find a representative palette for the source image and builds a new image
  // where each pixel is replaced by the nearest palette color
  PImage quantize(PImage src, int k, color[] paletteOut) {
    
    // pull pixels into arrays of float values
    int n = src.width * src.height;
    float[] r = new float[n];
    float[] g = new float[n];
    float[] b = new float[n];
  
    // extract color values from the pixels
    src.loadPixels();
    for (int i = 0; i < n; i++) {
      color c = src.pixels[i];
      r[i] = red(c);
      g[i] = green(c);
      b[i] = blue(c);
    }
  
    // Initialize k cluster centroids at random
    float[] cr = new float[k];
    float[] cg = new float[k];
    float[] cb = new float[k];
  
    for (int j = 0; j < k; j++) {
      int p = (int) random(n); // pick a random pixel index
      cr[j] = r[p]; // use its color as the initial centroid j
      cg[j] = g[p];
      cb[j] = b[p];
    }
  
    int[] assign = new int[n]; // which centroid each pixel belongs to
  
    // Runs k-means algorithm for a number of iterations
    for (int iter = 0; iter < 10; iter++) {
      /* 3‑A: assignment step */
      for (int i = 0; i < n; i++) {
        float best = 1e9f; int bestIdx = 0;
        for (int j = 0; j < k; j++) {
          float dr = r[i] - cr[j];
          float dg = g[i] - cg[j];
          float db = b[i] - cb[j];
          float d2 = dr*dr + dg*dg + db*db; // squared Euclidean distance
          if (d2 < best) { best = d2; bestIdx = j; }
        }
        assign[i] = bestIdx;
      }
  
      // Accumulate channel sums for each cluster
      float[] sumR = new float[k];
      float[] sumG = new float[k];
      float[] sumB = new float[k];
      int[]   cnt  = new int[k];
  
      
      for (int i = 0; i < n; i++) {
        int a = assign[i];
        sumR[a] += r[i];
        sumG[a] += g[i];
        sumB[a] += b[i];
        cnt[a]++;
      }
      
      // Divide by cnt to move the centroid to the average color of its pixels
      for (int j = 0; j < k; j++) if (cnt[j] > 0) {
        cr[j] = sumR[j] / cnt[j];
        cg[j] = sumG[j] / cnt[j];
        cb[j] = sumB[j] / cnt[j];
      }
    }
  
    // Create the color table and build the quantized image
    color[] table = new color[k];
    for (int j = 0; j < k; j++) {
      table[j] = color(cr[j], cg[j], cb[j]);
      paletteOut[j] = color(cr[j], cg[j], cb[j]);
    }
  
    PImage out = createImage(src.width, src.height, ARGB);
    out.loadPixels();
    for (int i = 0; i < n; i++) {
      out.pixels[i] = table[ assign[i] ];
    }
    
    out.updatePixels();
    return out;
  }
  
  // GUI prompt for when the user saves, asking how much they'd like to upscale their image
  int promptUpscale() {
    String[] opts = { "2×", "4×", "8×", "16×", "32×", "64×" };
    java.awt.Component win = (java.awt.Component) parent.getSurface().getNative();
    Object choice = javax.swing.JOptionPane.showInputDialog(
          win,
          "Choose upscale factor:",
          "Export size",
          javax.swing.JOptionPane.PLAIN_MESSAGE,
          null,
          opts,
          opts[0]);
    println("[prompt] choice =", choice);
    if (choice == null) return -1;          // user hit cancel
    return Integer.parseInt(((String) choice).replace("×",""));
  }
  
  PImage upscaleCanvas(int factor) {
    
    PImage small = createCanvasImage();
    PImage big = createImage(small.width * factor, small.height * factor, ARGB);
    
    big.loadPixels();
    small.loadPixels();
  
    for (int y = 0; y < small.height; y++) {
      for (int x = 0; x < small.width; x++) {
        int src = small.pixels[y * small.width + x];
        
        // write a factor * factor block of that color to fill the pixels of the upscaled image
        for (int dy = 0; dy < factor; dy++) {
          int row = (y * factor + dy) * big.width;
          for (int dx = 0; dx < factor; dx++) {
            big.pixels[row + (x * factor + dx)] = src;
          }
        }
      }
    }
    big.updatePixels();
    return big;
  }

  private String getDownloadsPath() {
    String os = System.getProperty("os.name").toLowerCase();
    String home = System.getProperty("user.home");
    return os.contains("win") ? home + "\\\\Downloads\\\\"
                              : home +  "/Downloads/";
  }
  
}
