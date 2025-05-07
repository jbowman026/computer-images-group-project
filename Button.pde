class myButton {
  float x, y, w, h; //position and dimensions
  String label;
  boolean wasPressed = false; //tracks previous state

  myButton(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  } //constructor 

  // Returns true ONLY on the initial press
  boolean isClicked() {
    boolean isOver = (mouseX >= x && mouseX <= x + w && 
                     mouseY >= y && mouseY <= y + h);
    boolean isClick = isOver && mousePressed && !wasPressed;
    wasPressed = mousePressed; // Update state
    return isClick;
  }

  void display() {
    fill(isClicked() ? color(150) : color(100)); 
    rect(x, y, w, h, 5);
    fill(255);
    textAlign(CENTER, CENTER);
    text(label, x + w/2, y + h/2);
  }
}