#include <Wire.h>
#include <WaveHC.h>
#include <WaveUtil.h>
#include <MorpheusSlave.h>

/*
 * Define macro to put error messages in flash memory
 */
#define error(msg) error_P(PSTR(msg))

#define FILE_MAX   99

#define PIN_ADDR_MSB 6
#define PIN_ADDR_LSB 7

short addr = 0;

int maxIndex = FILE_MAX;

SdReader card;    // This object holds the information for the card
FatVolume vol;    // This holds the information for the partition on the card
FatReader root;   // This holds the information for the volumes root directory
FatReader file;   // This object represent the WAV file 
WaveHC wave;      // This is the only wave (audio) object, since we will only play one at a time

MorpheusSlave slave;

void setup()
{
  Serial.begin(115200);

  pinMode(PIN_ADDR_MSB, INPUT);
  pinMode(PIN_ADDR_LSB, INPUT);
  
  int l = digitalRead(PIN_ADDR_LSB);
  int h = digitalRead(PIN_ADDR_MSB);
  addr = h << 1 | l;

  randomSeed(analogRead(0));
  
  setupWave();
  indexFiles();
  
  Wire.begin(addr); // join i2c bus as a slave	
  Wire.onReceive(receiveEvent); // register event
  
  Serial.println("Morpheus audio bot: RDY :-)");
  Serial.print("My I2C address is: 0x");
  Serial.println(addr, HEX);
}

void receiveEvent(int n) {
  slave.receiveI2C(n);
}

void setupWave() {
  if (!card.init()) error("card.init");

  // enable optimized read - some cards may timeout
  card.partialBlockRead(true);

  if (!vol.init(card)) error("vol.init");

  if (!root.openRoot(vol)) error("openRoot");  
}

void reset() {
  Serial.println("reset");
  setupWave();
}

void test() {
  Serial.println("test");
  playRandom();
}

void loop()
{
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

void playRandom() {
  Serial.println("playRandom");
  playById(random(maxIndex+1));
}

void stopPlayback() {
  Serial.println("stopPlayback");
  wave.stop();
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
    
    Serial.print("Verifying: ");
    Serial.println(name);
    
    // Open file by name
    if (!file.open(root, name)) {
      maxIndex = i-1;
      break;
    }
  }
  
  Serial.print("maxIndex: ");
  Serial.println(maxIndex);
}


void playFromData() {
  int id = atoi(slave.data);
  playById(id);
}

void playById(int id) {
  if ( id <= 0 || id > maxIndex ) {
    Serial.print("Invalid Id: "); 
    Serial.println(id);
    return;
  }

  char name[7];
  sprintf(name,"%02d.WAV",id);
  Serial.print("Playing: ");
  Serial.println(name);

  wave.stop();
  
  if (!file.open(root, name))  {
    Serial.println("Error opening file"); 
    return;
  }
    
  // create wave and start play
  if (!wave.create(file)) {
    Serial.println("Error creating wave object"); 
    return;
  }
  
  wave.play();
}
