class Button {
  float x, y, w, h;
  String label;

  // true while the mouse button is held down and the press began inside this button
  boolean armed = false;

  // basic colours – tweak as you like
  color idle  = color(100);
  color hover = color(120);
  color down  = color(150);

  Button(float x, float y, float w, float h, String label) {
    this.x = x; this.y = y; this.w = w; this.h = h; this.label = label;
  }

  // ----- helpers -----
  boolean isOver() {
    return mouseX >= x && mouseX <= x + w &&
           mouseY >= y && mouseY <= y + h;
  }

  // ----- event hooks -----
  void mousePressed() {
    if (isOver()) armed = true;          // start a potential click
  }

  /** Returns true exactly once when a click completes */
  boolean mouseReleased() {
    boolean clicked = armed && isOver(); // press & release both inside
    armed = false;                       // reset either way
    return clicked;
  }

  // ----- drawing -----
  void display() {
    if      (armed)    fill(down);
    else if (isOver()) fill(hover);
    else               fill(idle);

    rect(x, y, w, h, 5);

    fill(255);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }
}
