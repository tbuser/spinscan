import processing.serial.*;
import processing.video.*;
import hypermedia.video.*;
import controlP5.*;

ControlP5 controlP5;
Serial serial;
Capture cam;
MovieMaker movie;
OpenCV opencv;

int width = 860;
int height = 720;
int framerate = 30;
int threshold = 10;

String serialResponse = null;
boolean recording = false;

String serialPort = null;
String camPort = null;

boolean serialConnected = false;
boolean camConnected = false;

String[] serialPorts;
String[] camPorts;

ListBox serialList;
ListBox camList;
CheckBox laserBox;
Textfield camHFOVField;
Textfield camVFOVField;
Textfield camDistanceField;
Textfield laserOffsetField;

String textureFilename = "texture.mov";
String laserFilename = "laser.mov";

// degrees
float camHFOV = 50.0;
// degrees
float camVFOV = camHFOV * 4.0 / 5.0;
// from camera to center of table in mm
float camDistance = 304.8;
// degrees
float laserOffset = 15.0;

int avgHorizontal = 10;
int avgVertical = 10;

int brightness = 0;
int contrast = 0;

void setup() {
  size(width,height);
//  smooth();
  frameRate(framerate);

  opencv = new OpenCV(this);
  opencv.allocate(640, 480);

  controlP5 = new ControlP5(this);

  laserBox = controlP5.addCheckBox("laserBox", 10, 55);  
  laserBox.setItemsPerRow(1);
  laserBox.setSpacingColumn(30);
  laserBox.setSpacingRow(10);
  laserBox.addItem("Laser", 1);

  controlP5.addButton("textureScan", 0, 10, 70, 90, 15).captionLabel().set("Record Texture");
  controlP5.addButton("laserScan", 0, 120, 70, 90, 15).captionLabel().set("Record Laser");

  camPorts = Capture.list();
  camList = controlP5.addListBox("camList", 10, 50, 200, 120);
  camList.setItemHeight(15);
  camList.setBarHeight(15);
  camList.captionLabel().set("Select Camera");
  camList.captionLabel().style().marginTop = 3;
  for (int i = 0; i < camPorts.length; i++) {
    camList.addItem(camPorts[i], i);
  }
  camList.close();

  serialPorts = Serial.list();
  serialList = controlP5.addListBox("serialList", 10, 30, 200, 120);
  serialList.setItemHeight(15);
  serialList.setBarHeight(15);
  serialList.captionLabel().set("Select Serial Port");
  serialList.captionLabel().style().marginTop = 3;
  for (int i = 0; i < serialPorts.length; i++) {
    serialList.addItem(serialPorts[i], i);
  }
  serialList.close();

  camHFOVField = controlP5.addTextfield("camHFOV", 10, 200, 90, 15);
  camHFOVField.captionLabel().set("Camera HFOV (deg)");
  camHFOVField.setText(str(camHFOV));

  camVFOVField = controlP5.addTextfield("camVFOV", 120, 200, 90, 15);
  camVFOVField.captionLabel().set("Camera VFOV (deg)");
  camVFOVField.setText(str(camVFOV));

  camDistanceField = controlP5.addTextfield("camDistance", 10, 240, 90, 15);
  camDistanceField.captionLabel().set("Camera Distance (mm)");
  camDistanceField.setText(str(camDistance));

  laserOffsetField = controlP5.addTextfield("laserOffset", 10, 280, 90, 15);
  laserOffsetField.captionLabel().set("Laser Offset (deg)");
  laserOffsetField.setText(str(laserOffset));

  controlP5.addSlider("brightness", -128, 128, contrast, 10, 120, 150, 10);
  Slider contrastSlider = (Slider)controlP5.controller("contrast");
  
  controlP5.addSlider("contrast", -128, 128, contrast, 10, 140, 150, 10);
  Slider brightnessSlider = (Slider)controlP5.controller("brightness");
}

void draw() {
  background(color(0,0,0));

  if (camConnected) {
    cam.read();
    PImage camImage = cam.get();
    opencv.copy(camImage);

    opencv.brightness(brightness);
    opencv.contrast(contrast);

    PImage opencvImage = opencv.image();

    image(opencvImage, 220, 0);    
    
//    opencvImage.loadPixels();

    if (recording) {
      movie.addFrame(opencvImage.pixels, opencvImage.width, opencvImage.height);
    }

    stroke(255);
    line(640/2+220, 0, 640/2+220, 480);
    line(220, 480/2, 640+220, 480/2);
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    // an event from a group e.g. scrollList
    String groupName = theEvent.group().name();
    float groupValue = theEvent.group().value();
    
    if (groupName == "serialList") {
      serialPort = serialPorts[int(groupValue)];
      serialList.captionLabel().set(serialPort);
      serialList.close();
      serialConnect();
    } else if (groupName == "camList") {
      camPort = camPorts[int(groupValue)];
      camList.captionLabel().set(camPort);
      camList.close();
      camConnect();
    } else if (groupName == "laserBox") {
      if (theEvent.group().arrayValue()[0] == 1.0) {
        laser(true);
      } else {
        laser(false);
      }
    } else {
      println("ERROR: Unknown group " + groupName);
    }
  }
}

void serialEvent(Serial serial) {
  serialResponse = serial.readStringUntil('\n');
  if (recording) {
    recording = false;
    delay(50);
    movie.finish();
  }
  println("RECEIVED: " + serialResponse);
}

public void laser(boolean on) {
  if (serialConnected && !recording) {
    if (on) {
      serial.write('1');
    } else {
      serial.write('0');
    }
  }
}

public void laserScan(int theValue) {
  if (serialConnected) {
    movie = new MovieMaker(this, 640, 480, laserFilename, framerate, MovieMaker.VIDEO, MovieMaker.LOSSLESS);
    serial.write('3');
    delay(50);
    recording = true;
  } else {
    println("ERROR: Serial not connected");
  }
}

public void textureScan(int theValue) {
  if (serialConnected) {
    movie = new MovieMaker(this, 640, 480, textureFilename, framerate, MovieMaker.VIDEO, MovieMaker.LOSSLESS);
    serial.write('2');
    delay(50);
    recording = true;
  } else {
    println("ERROR: Serial not connected");
  }
}

public void serialConnect() {
  serial = new Serial(this, serialPort, 9600);
  serial.bufferUntil('\n');
  serialConnected = true;
}

public void camConnect() {
  cam = new Capture(this, 640, 480, camPort, framerate);
  camConnected = true;
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

