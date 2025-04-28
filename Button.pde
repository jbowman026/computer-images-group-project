/*
Button class for gui controls

*/
class Button {
  PVector pos;
  float w, h;
  color btnColor;
  String label;
  int radius;
  Boolean inBounds = false, clicked = false;
  
  
  Button(int x, int y, int w, int h, String lbl, color Color, int rad){
  pos = new PVector(x, y);
  this.w = w;
  this.h = h;
  label = lbl;
  btnColor = Color;
  radius = rad;
  }
  
  //confirm that button is clicked
  boolean isClicked(){
    return clicked;
  }
  
  //place within draw to continuously track for clicks on the button
  void update(){
    float xpos = pos.x, ypos = pos.y;  //hold PVector positions
    
    //verify if mouse is on the button and user is clicking within it
    if(mousePressed && !inBounds){
      inBounds = true;
      if(mouseX >= xpos && mouseX <= xpos + w && mouseY >= ypos && mouseY <= ypos + h){
        clicked = true;
      }
    } else inBounds = clicked = false;
  }
  
  void display(){
  float adjW = w/2, adjH = h/2;
  
  fill(btnColor);
  
  //place button details inside of rectangle
  rect(pos.x, pos.y, w, h, radius);
  fill(0);
  
  //centering text within button
  textAlign(CENTER, CENTER);
  textSize(12);
  text(label, pos.x + adjW, pos.y + adjH);
  }
  
}
