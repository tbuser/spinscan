import processing.serial.*;
import processing.video.*;
import controlP5.*;

Capture cam;
MovieMaker mm;
Serial serial;
ControlP5 controlP5;

int width = 640;
int height = 480;
int framerate = 30;
int threshold = 10;
String result = null;
boolean recording = false;

void setup() {
  size(width,height);
  smooth();
  frameRate(framerate);
  
  println(Serial.list());
  serial = new Serial(this, "/dev/tty.usbserial-A900ceEj", 9600);
  serial.bufferUntil('\n');
  
  controlP5 = new ControlP5(this);
  controlP5.addButton("scanButton",0,10,10,80,19);
  
  println(Capture.list());
  cam = new Capture(this, width, height, Capture.list()[2], framerate);
  
  mm = new MovieMaker(this, width, height, "scan.mov", framerate, MovieMaker.H263, MovieMaker.HIGH);
}

void draw() {
  background(color(0,0,0));

  cam.read();
  image(cam, 0, 0);
  
  if (recording) {
    mm.addFrame();
  }
}

void serialEvent(Serial serial) {
  result = serial.readStringUntil('\n');
  if (recording) {
    recording = false;
    mm.finish();
  }
  println(result);
}

public void scanButton(int theValue) {
  serial.write('3');
  recording = true;
}

//void setup() {
//  size(w * 2, h);
//  opencv = new OpenCV(this);
//  opencv.movie("gnome360.mov", w, h);
//  //opencv.movie("tux.avi", w, h);
//}
//
//void draw() {
//  opencv.read();
//
//  PImage img = opencv.image();
//
//  image(img, 0, 0);  
//  
//  int brightestX = 0;
//  float brightestValue = 0;
//  img.loadPixels();
//  int index = 0;
//  for (int y = 0; y < h; y++) {
//    brightestValue = 0;
//    brightestX = 0;
//    for (int x = 0; x < w; x++) {
//      int pixelValue = img.pixels[index];
//      float pixelBrightness = brightness(pixelValue);
//      if (pixelBrightness > brightestValue && pixelBrightness > threshold) {
//        brightestValue = pixelBrightness;
//        brightestX = x;
//      }
//      index++;
//    }
//    if (brightestX > 0) {
//      img.pixels[y*w+brightestX] = color(0, 255, 0);
//    }
//  }
//
//  img.updatePixels();
//  image(img, w, 0);  
//}

