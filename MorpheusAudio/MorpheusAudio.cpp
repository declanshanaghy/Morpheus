#include "MorpheusAudio.h"

MorpheusAudio::MorpheusAudio(int addr)
{
	_addr = addr;
}

void MorpheusAudio::stop() {
	Wire.beginTransmission(_addr);
	Wire.send((short)'s');
	Wire.endTransmission();
}

void MorpheusAudio::playRandom() {
	playRandom(1);
}

void MorpheusAudio::playRandom(uint8_t nLoop) {
	Wire.beginTransmission(_addr);
	Wire.send((short)'r');
	Wire.send(nLoop);
	Wire.endTransmission();
}

void MorpheusAudio::playById(uint8_t nLoop, uint8_t nId) {
	Wire.beginTransmission(_addr);
	Wire.send((short)'p');
	Wire.send(nLoop);
	Wire.send(nId);
	Wire.endTransmission();
}

void MorpheusAudio::indexFiles() {
	Wire.beginTransmission(_addr);
	Wire.send((short)'i');
	Wire.endTransmission();
}

