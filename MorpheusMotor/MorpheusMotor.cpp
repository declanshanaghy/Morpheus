#include "MorpheusMotor.h"

MorpheusMotor::MorpheusMotor(int addr)
{
	_addr = addr;
}

boolean MorpheusMotor::setServoParams(short n, short angle) {
	if ( n < 1 || n > 4 ) {
#ifdef DBG		
		Serial.print("Invalid servo number: ");
		Serial.println(n);		
#endif
		return false;
	}
	if ( angle < 0 || angle > 180 ) {
#ifdef DBG		
		Serial.print("Invalid angle: ");
		Serial.println(angle);		
#endif
		return false;
	}
	
	Wire.beginTransmission(_addr);
	Wire.send((short)'e' + n-1);
	Wire.send(angle);
	Wire.endTransmission();
	return true;
}

boolean MorpheusMotor::setDCMotorParams(short n, short dir, short spd) {
	if ( n < 1 || n > 4 ) {
#ifdef DBG		
		Serial.print("Invalid motor number: ");
		Serial.println(n);		
		return false;
#endif
	}
	if ( dir < 1 || dir > 4 ) {
#ifdef DBG		
		Serial.print("Invalid direction: ");
		Serial.println(dir);		
#endif
		return false;
	}
	if ( spd < 0 || spd > 255 ) {
#ifdef DBG		
		Serial.print("Invalid speed: ");
		Serial.println(spd);		
#endif
		return false;
	}

	Wire.beginTransmission(_addr);
	Wire.send((short)'a' + n-1);
	Wire.send((short)'1' + dir-1);
	Wire.send((short)spd);
	Wire.endTransmission();
	return true;
}
	
void MorpheusMotor::testDCMotors() {
	Wire.beginTransmission(_addr);
	Wire.send((short)'t');
	Wire.send((short)'d');
	Wire.endTransmission();
}

void MorpheusMotor::testServos() {
	Wire.beginTransmission(_addr);
	Wire.send((short)'t');
	Wire.send((short)'s');
	Wire.endTransmission();
}
