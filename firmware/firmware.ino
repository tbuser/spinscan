int ledPin =  13;
int laserPin = 2;
int dirPin = 3;
int stepPin = 4;
float gearRatio = 61.0/10.0;

void setup() {
  pinMode(laserPin, OUTPUT);
  pinMode(dirPin, OUTPUT);
  pinMode(stepPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  
  Serial.begin(9600);
}

void rotate(int steps, float speed){
  //rotate a specific number of microsteps (8 microsteps per step) - (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger
  int dir = (steps > 0)? HIGH:LOW;
  steps = abs(steps);

  digitalWrite(dirPin,dir); 

  float usDelay = (1/speed) * 70;

  for(int i=0; i < steps; i++){
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(usDelay); 

    digitalWrite(stepPin, LOW);
    delayMicroseconds(usDelay);
  }
} 

void rotateDeg(float deg, float speed){
  //rotate a specific number of degrees (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger
  int dir = (deg > 0)? HIGH:LOW;
  digitalWrite(dirPin,dir); 

  int steps = abs(deg)*(1/0.225)*gearRatio;
  float usDelay = (1/speed) * 70;

  for(int i=0; i < steps; i++){
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(usDelay); 

    digitalWrite(stepPin, LOW);
    delayMicroseconds(usDelay);
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
    rotateDeg(360, 0.03);
    Serial.println("OK");
  } else if (val == '3') {
    laser(true);
    rotateDeg(360, 0.03);
    laser(false);
    Serial.println("OK");
  } else {
    Serial.println("Unknown Command");
  }

  delay(50);
  
  Serial.flush();
}
