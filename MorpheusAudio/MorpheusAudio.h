#ifndef MorpheusAudio_h
#define MorpheusAudio_h

#include "WProgram.h"
#include <Wire.h>

class MorpheusAudio
{
public:
    MorpheusAudio(int addr);
	void stop();
	void playRandom();
	void playRandom(uint8_t nLoop);
	void indexFiles();
	
private:
    int _addr;
};

#endif

