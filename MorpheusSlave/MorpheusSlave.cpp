#include "MorpheusSlave.h"

MorpheusSlave::MorpheusSlave()
{
	reset();
	
	// if analog input pin 0 is unconnected, random analog
	// noise will cause the call to randomSeed() to generate
	// different seed numbers each time the sketch runs.
	// randomSeed() will then shuffle the random function.
	randomSeed(analogRead(0));
}

boolean MorpheusSlave::newCommand() {
	return _exec;
}

void MorpheusSlave::reset() {
#if DBG
	Serial.println("reset");
#endif
	_lastRX = -1;
	_exec = false;
	command = NULL;
    data = NULL;	
}

uint8_t MorpheusSlave::getData(int pos) {
	return data.charAt(pos);
}

uint8_t MorpheusSlave::getAscii09(int pos) {
	int d = data.charAt(pos);
    if ( d >= 48 && d <= 57 )
        //Convert from ascii to int
        d -= 48;
    return d;
}

char MorpheusSlave::getChar(int pos) {
	return data.charAt(pos);
}

void MorpheusSlave::endComm() {
	_lastRX = -1;
	_exec = true;
	//Serial.flush();
    
#if DBG
	Serial.print("command: ");
	Serial.println(command);
	Serial.print("data: ");
	Serial.println(data);
#endif
}

void MorpheusSlave::receiveSerial() {
	if ( Serial.available() )  {
		char b;
		while ( Serial.available() > 0 ) {
			_lastRX = millis();
			b = Serial.read();
#if DBG
			Serial.print("B: ");
			Serial.println(b);
#endif
			if ( b == '\n' ) {
				endComm();
				break;
			}
			else if ( command == NULL ) {
				command = b;
				data = "";
			}
			else {
				data += b;
			}
		}
    }
	
	if ( _lastRX != -1 && millis() - _lastRX > RX_TIMEOUT ) {
		endComm();
	}
}

void MorpheusSlave::receiveEthernet(EthernetClient& incoming) {
	if ( incoming.available() )  {
		char b;
		while ( incoming.available() > 0 ) {
			_lastRX = millis();
			b = incoming.read();
#if DBG
			Serial.print("B: ");
			Serial.println(b);
#endif
			if ( b == '\n' ) {
				endComm();
				break;
			}
			else if ( command == NULL ) {
				command = b;
				data = "";
			}
			else {
				data += b;
			}
		}
    }
	
	if ( _lastRX != -1 && millis() - _lastRX > RX_TIMEOUT ) {
		endComm();
	}
}

void MorpheusSlave::receiveI2C(int n) {	
	int i = 0;
	char b;
	while ( Wire.available() > 0 ){
		b = Wire.read();
#if DBG
		Serial.print("B: ");
		Serial.println(b);
#endif
		switch ( i++ ) {
			case 0:
				command = b;
				data = "";
				break;
			default:
				data += b;
				break;
		}
	}
	
	endComm();
}
