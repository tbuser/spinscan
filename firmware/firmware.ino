// define some pins
//=================
#define DIR_PIN 3
#define STEP_PIN 4
#define ENABLE_PIN 8
#define SLEEP_PIN 9
#define MS1_PIN 11
#define MS2_PIN 12
#define MS3_PIN 13
#define LASER_PIN 2
#define LED_PIN 13

// define stepper
//===============
// 200 * 16 microstepping
#define STEPS_PER_REV 3200

#define RPM 0.5

void setup() {
  pinMode(LASER_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(STEP_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  
  // initialise the Pololu
  //==========================
  digitalWrite(MS1_PIN, HIGH);
  digitalWrite(MS2_PIN, HIGH);
  digitalWrite(MS3_PIN, HIGH);
  digitalWrite(ENABLE_PIN, LOW);
  digitalWrite(SLEEP_PIN, LOW);
  delay(100);
  
  Serial.begin(9600);
}

// speed = rpm
void rotate(float degrees, float speed) {
  digitalWrite(SLEEP_PIN, HIGH);
  digitalWrite(ENABLE_PIN, LOW);

  int steps_per_second = speed * STEPS_PER_REV / 60;
  int step_delay = 1000 / steps_per_second;
  float steps = STEPS_PER_REV * (degrees/360);
  int dir = (degrees > 0) ? LOW : HIGH;
  
  digitalWrite(DIR_PIN, dir);
  delay(100);

  for(int i=0; i < steps; i++){
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(STEP_PIN, LOW);
    delay(step_delay);
  }
  
  digitalWrite(SLEEP_PIN, LOW);
  digitalWrite(ENABLE_PIN, HIGH);
}

void laser(boolean state) {
  digitalWrite(LED_PIN, state);
  digitalWrite(LASER_PIN, state);
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
    rotate(360.0, RPM);
    Serial.println("OK");
  } else if (val == '3') {
    laser(true);
    rotate(360.0, RPM);
    laser(false);
    Serial.println("OK");
  } else {
    Serial.println("Unknown Command");
  }

  delay(50);
  
  Serial.flush();
}

