#ifndef MorpheusMotor_h
#define MorpheusMotor_h

#include "WProgram.h"
#include <Wire.h>

class MorpheusMotor
{
public:
    MorpheusMotor(int addr);
	boolean setDCMotorParams(short n, short dir, short spd);
	boolean setServoParams(short n, short angle);
	void testDCMotors();
	void testServos();
	
private:
    int _addr;
};

#endif

