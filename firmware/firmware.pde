int ledPin =  13;
int laserPin = 2;
int dirPin = 3;
int stepPin = 4;
int stepSpeed = 4000;
float gearRatio = 61/10;

void setup() {
  pinMode(laserPin, OUTPUT);
  pinMode(dirPin, OUTPUT);
  pinMode(stepPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  
  Serial.begin(9600);
}

void stepper(float turnDegrees, int stepSpeed) {
  boolean dir;
  float steps;
  
  if (turnDegrees > 0) {
    dir = true;
  } else {
    dir = false;
  }
  
  digitalWrite(dirPin, dir);

//  delay(50);

  steps = turnDegrees/360.0 * 1600.0 * gearRatio;

  for (int i=0; i<steps ;i++) {
    digitalWrite(stepPin, LOW);
//    delayMicroseconds(150);
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(stepSpeed);
  }
}

void laser(boolean state) {
  digitalWrite(ledPin, state);
  digitalWrite(laserPin, state);
}

void loop() {
  while (Serial.available() == 0);

  int val = Serial.read();

  if (val == '0') {
    laser(false);
    Serial.println("OK");
  } else if (val == '1') {
    laser(true);
    Serial.println("OK");
  } else if (val == '2') {
    stepper(360, stepSpeed);
    Serial.println("OK");
  } else if (val == '3') {
    laser(true);
    stepper(360, stepSpeed);
    laser(false);
    Serial.println("OK");
  } else if (val == '4') {
    stepper(360, stepSpeed);
    Serial.println("OK");
  } else {
    Serial.println("Unknown Command");
  }

  delay(50);
  
  Serial.flush();
}
