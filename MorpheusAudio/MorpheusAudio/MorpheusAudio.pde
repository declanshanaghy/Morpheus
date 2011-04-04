#include <Wire.h>
#include <WaveHC.h>
#include <WaveUtil.h>
#include <MorpheusSlave.h>

/*
 * Define macro to put error messages in flash memory
 */
#define error(msg) error_P(PSTR(msg))

#define FILE_MAX   99

#define PIN_ADDR_MSB A1
#define PIN_ADDR_LSB A2

#define DBG 0

short addr = 0;
int maxIndex = FILE_MAX;

SdReader card;    // This object holds the information for the card
FatVolume vol;    // This holds the information for the partition on the card
FatReader rootReader;   // This holds the information for the volumes root directory
FatReader fReader;   // This object represent the WAV file 
WaveHC wave;      // This is the only wave (audio) object, since we will only play one at a time

MorpheusSlave slave = MorpheusSlave(3);

uint8_t loopCount = 0;
uint8_t loopMax = 0;
boolean playLoop = false;

void setup()
{
  Serial.begin(115200);

  pinMode(PIN_ADDR_MSB, INPUT);
  pinMode(PIN_ADDR_LSB, INPUT);
  
  int l = digitalRead(PIN_ADDR_LSB);
  int h = digitalRead(PIN_ADDR_MSB);
  addr = h << 1 | l;

  randomSeed(analogRead(A0));
  
  setupWave();
  indexFiles();
  
  Wire.begin(addr); // join i2c bus as a slave	
  Wire.onReceive(receiveEvent); // register event
  
  Serial.println("Morpheus audio bot: RDY :-)");
  Serial.print("My I2C address is: 0x");
  Serial.println(addr, HEX);
}

void loop()
{
  checkPlayLoop();
  slave.receiveSerial();
  
  if ( slave.newCommand() ) {
    switch ( slave.command ) {
      case 'i':
        indexFiles();
        break;
      case 'p':
        playFromData();
        break;
      case 'r':
        playRandom();
        break;
      case 's':
        stopPlayback();
        break;
      case 't':
        test();
        break;
      case 'z':
        reset();
        break;
      default:
        Serial.println("Command not handled");
    }    
    
    slave.reset();
  }
  
}

void checkPlayLoop() {
  boolean notPlaying = !wave.isplaying;
  boolean moreLoops = loopCount < loopMax;
  
  if ( playLoop && notPlaying ) {
    if ( loopMax != 255 )  //255 means loop infinitely
      loopCount++;
    wave.seek(0);
    wave.play();
    if ( loopCount >= loopMax )
      resetPlayLoop();
  }
}

void receiveEvent(int n) {
  slave.receiveI2C(n);
}

void setupWave() {
  if (!card.init()) error("card.init");

  // enable optimized read - some cards may timeout
  card.partialBlockRead(true);

  if (!vol.init(card)) error("vol.init");

  if (!rootReader.openRoot(vol)) error("openRoot");  
  
  resetPlayLoop();
}

void resetPlayLoop() {
  playLoop = false;
  loopCount = 0;
  loopMax = 0;
}

void playFromData() {
  loopMax = slave.getData(0);
  uint8_t id = slave.getData(1);
  playById(id);
}

void reset() {
#ifdef DBG  
  Serial.println("reset");
#endif
  stopPlayback();
  setupWave();
}

void test() {
#ifdef DBG  
  Serial.println("test");
#endif
  loopCount = 0;
  playRandom();
}

void playRandom() {
#ifdef DBG
  Serial.println("playRandom");
#endif
  loopMax = slave.getData(0);
  playById(random(1,maxIndex+1));
}

void stopPlayback() {
#ifdef DBG  
  Serial.println("stopPlayback");
#endif
  resetPlayLoop();
  if ( wave.isplaying ) {
    wave.stop();
  }
}

/////////////////////////////////// HELPERS
/*
 * print error message and halt
 */
void error_P(const char *str) {
  PgmPrint("Error: ");
  SerialPrint_P(str);
  sdErrorCheck();
  while(1);
}

/*
 * print error message and halt if SD I/O error, great for debugging!
 */
void sdErrorCheck(void) {
  if (!card.errorCode()) return;
  PgmPrint("\r\nSD I/O error: ");
  Serial.print(card.errorCode(), HEX);
  PgmPrint(", ");
  Serial.println(card.errorData(), HEX);
  while(1);
}

/*
 * Find files and save file index.  A file's index is is the
 * index of it's directory entry in it's directory file. 
 */
void indexFiles(void)
{
  char name[7];
  
  // copy flash string to RAM
  strcpy_P(name, PSTR("XX.WAV"));
  
  for (uint8_t i = 0; i < FILE_MAX; i++) {
    sprintf(name, "%02d.WAV", i);
    
#ifdef DBG  
    Serial.print("Verifying: ");
    Serial.println(name);
#endif

    // Open file by name
    if (!fReader.open(rootReader, name)) {
      maxIndex = i-1;
      break;
    }
  }
  
#ifdef DBG  
  Serial.print("maxIndex: ");
  Serial.println(maxIndex);
#endif
}

boolean playById(int id) {
  if ( id <= 0 || id > maxIndex ) {
#ifdef DBG  
    Serial.print("Invalid Id: "); 
    Serial.println(id);
#endif
    return false;
  }

  char name[7];
  sprintf(name,"%02d.WAV",id);
#ifdef DBG  
  Serial.print("Playing: ");
  Serial.println(name);
#endif

  if ( wave.isplaying )
    wave.stop();
  
  if (!fReader.open(rootReader, name))  {
#ifdef DBG  
    Serial.println("Error opening file"); 
#endif
    return false;
  }
    
  // create wave and start play
  if (!wave.create(fReader)) {
#ifdef DBG
    Serial.println("Error creating wave object"); 
#endif
    return false;
  }
  
  loopCount = 1;
  playLoop = loopMax > 1;
  wave.play();
  return true;
}
