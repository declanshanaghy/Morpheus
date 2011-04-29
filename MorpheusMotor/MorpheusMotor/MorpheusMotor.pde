#include <Wire.h>
#include <Servo.h>
#include <AFMotor.h>
#include <MorpheusSlave.h>

#define PIN_ADDR_MSB A2
#define PIN_ADDR_LSB A1

#define PIN_SRV_V    A0
#define PIN_SRV_H    9

short addr = 0;
MorpheusSlave slave = MorpheusSlave(3);
uint8_t dir;
uint16_t spd;
uint16_t angle;

AF_DCMotor mr(2, MOTOR34_1KHZ); // create motor #1, 64KHz pwm
AF_DCMotor ml(3, MOTOR34_1KHZ); // create motor #4, 64KHz pwm
Servo sv; 
Servo sh; 

#define DBG 0

void setup()
{
  Serial.begin(115200);

  pinMode(PIN_ADDR_MSB, INPUT);
  pinMode(PIN_ADDR_LSB, INPUT);

  int l = digitalRead(PIN_ADDR_LSB);
  int h = digitalRead(PIN_ADDR_MSB);
  addr = 1 << 2 | h << 1 | l;

  Wire.begin(addr); // join i2c bus as a slave	
  Wire.onReceive(receiveEvent); // register event

  Serial.println("Morpheus motor bot: RDY :-)");
  Serial.print("My I2C address is: 0x");
  Serial.println(addr, HEX);

  sv.attach(PIN_SRV_V);
  sh.attach(PIN_SRV_H);
  
  reset();
}

void receiveEvent(int n) {
  slave.receiveI2C(n);
}

void setVertical(int angle) {
  sv.write(angle);
}

void setHorizontal(int angle) {
  sh.write(angle);
}

void reset() {
#if DBG
  Serial.println("reset");
#endif
  setHorizontal(90);
  setVertical(90);
  
  ml.setSpeed(0);
  ml.run(RELEASE);

  mr.setSpeed(0);
  mr.run(RELEASE);
}

void extractServoParams() {
  angle = slave.getData(0);
  if ( angle < 0 ) {
#if DBG
    Serial.println("ERROR: angle < 0");
#endif
    angle = 0;
  }
  else if ( angle > 180 ) {
#if DBG
    Serial.println("ERROR: angle > 180");
#endif
    angle = 180;
  }

#if DBG
  Serial.print("angle: ");
  Serial.println(angle);
#endif
}

void extractDCMotorParams() {
  spd = slave.getData(1);
  if ( spd > 255 ) {
#if DBG
    Serial.print("ERROR: speed > 255: ");
#endif
    spd = 255;
  }
  else if ( spd < 0 ) {
#if DBG
    Serial.print("ERROR: speed < 0: ");
#endif
    spd = 0;
  }

  char cDir = slave.getChar(0);
  switch (cDir) {
    case '1':
    case 'f':
      cDir = 'f';
      dir = FORWARD;
      break;
    case '2':
    case 'b':
      cDir = 'b';
      dir = BACKWARD;
      break;
    case '3':
    case 's':
      cDir = 's';
      dir = BRAKE;
      spd = 0;
      break;
    case '4':
    case 'r':
      cDir = 'r';
      dir = RELEASE;
      spd = 0;
      break;
    default:
#if DBG
      Serial.println("ERROR: Unsupported direction");
#endif
      dir = BRAKE;
      spd = 0;
  }

#if DBG
  Serial.print(cDir);
  Serial.print(", ");
  Serial.println(spd);
#endif
}

void loop() {
  slave.receiveSerial();

  if ( slave.newCommand() ) {
    switch ( slave.command ) {
    case 'a':  //Motor 1
#if DBG
      Serial.print("motor a: ");
#endif
      extractDCMotorParams();
      mr.setSpeed(spd);
      mr.run(dir);
      break;
    case 'd':  //Motor 4
#if DBG
      Serial.print("motor d: ");
#endif
      extractDCMotorParams();
      ml.setSpeed(spd);
      ml.run(dir);
      break;
    case 'r':
#if DBG
      Serial.println("release");
#endif
      ml.run(RELEASE);
      mr.run(RELEASE);
      break;
    case 's':
#if DBG
      Serial.println("brake");
#endif
      ml.setSpeed(0);
      mr.setSpeed(0);
      ml.run(BRAKE);
      mr.run(BRAKE);
      break;
    case 't':
      switch ( slave.data[0] ) {
        case 'd':
          testDCMotors();
          break;
        case 's':
          testServos();
          break;
//        default:
//          testDCMotors();
//          testServos();
//          break;
      }
      break;
    case 'e':
#if DBG
      Serial.print("vert: ");
#endif
      extractServoParams();
      setVertical(angle);
      break;
    case 'f':
#if DBG
      Serial.print("horiz: ");
#endif
      extractServoParams();
      setHorizontal(angle);
      break;
    case 'z':
      reset();
      break;
    case NULL:
      reset();
      break;
    default:
      Serial.print("Command not handled: ");
      Serial.print(slave.command);
      break;
    }    

    slave.reset();
  }
}

void testServos() {
#if DBG
  Serial.println("Test servos");
#endif
  
  sv.write(0);
  sh.write(0);

  delay(1000);

  sv.write(180);
  sh.write(180);  
}

void testDCMotors() {
#if DBG
  Serial.println("testDCMotors");
#endif

  ml.setSpeed(255);
  mr.setSpeed(255);

  ml.run(FORWARD);
  mr.run(BACKWARD);
  delay(500);

  ml.run(BACKWARD);
  mr.run(FORWARD);
  delay(500);

  ml.run(RELEASE);
  mr.run(RELEASE);
}


