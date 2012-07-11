#ifndef MorpheusSlave_h
#define MorpheusSlave_h

#include <Arduino.h>
#include <Wire.h>
#include <Ethernet.h>

#define RX_TIMEOUT	100
#define DBG 0

class MorpheusSlave
{
public:
    MorpheusSlave();

	char command;
	String data;
	
	void reset();
	boolean newCommand();
	
	void receiveSerial();
	void receiveI2C(int n);
	void receiveEthernet(EthernetClient& client);
	uint8_t getData(int pos);
	uint8_t getAscii09(int pos);    
	char getChar(int pos);

private:
	unsigned long _lastRX;
	boolean _exec;
		
	void endComm();
};

#endif

