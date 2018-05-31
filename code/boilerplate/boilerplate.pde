void render() {
  /* Write your drawing code here */
  background(255, 255, 255);
  noFill();
  //ellipse(width/2, height/2, 100, 100);
  ellipse(width/2, height/2, 200, 200);
  ellipse(450, height/2, 200, 200);
  ellipse(50, height/2, 200, 200);
  
  line(0, 0, width, height);
  line(0, height, width, 0);
  line(-100, -100, width + 100, height + 100);
  line(-100, height + 100, width + 100, -100);
  
  ellipse(width/2, height/2, 400, 200);
  ellipse(450, height/2, 400, 200);
  ellipse(50, height/2, 400, 200);
  
  // https://processing.org/examples/shapeprimitives.html
  triangle(18, 18, 18, 360, 81, 360);
  rect(81, 81, 63, 63);
  quad(189, 18, 216, 18, 216, 360, 144, 360);
  ellipse(252, 144, 72, 72);
  triangle(288, 18, 351, 360, 288, 360);
  //arc(250, 250, 100, 100, PI, TWO_PI);
  
  curve(5, 26, 5, 26, 73, 24, 73, 61); 
  curve(5, 26, 73, 24, 73, 61, 15, 65); 
  curve(73, 24, 73, 61, 15, 65, 15, 65);
  bezier(85, 20, 10, 10, 90, 90, 15, 80);
}