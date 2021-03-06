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
	void playById	(uint8_t nLoop, uint8_t nId);
	void indexFiles();
	
private:
    int _addr;
};

#endif

