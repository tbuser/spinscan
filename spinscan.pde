import hypermedia.video.*;

OpenCV opencv;

int w = 640;
int h = 480;
int threshold = 10;

void setup() {
  size(w * 2, h);
  opencv = new OpenCV(this);
  opencv.movie("gnome360.mov", w, h);
}

void draw() {
  opencv.read();

  PImage img = opencv.image();
  
  int brightestX = 0;
  float brightestValue = 0;
  img.loadPixels();
  int index = 0;
  for (int y = 0; y < h; y++) {
    brightestValue = 0;
    brightestX = 0;
    for (int x = 0; x < w; x++) {
      int pixelValue = img.pixels[index];
      float pixelBrightness = brightness(pixelValue);
      if (pixelBrightness > brightestValue && pixelBrightness > threshold) {
        brightestValue = pixelBrightness;
        brightestX = x;
      }
      index++;
    }
    if (brightestX > 0) {
      img.pixels[y*w+brightestX] = color(0, 255, 0);
    }
  }

  img.updatePixels();
  image(img, 0, 0);  
}

