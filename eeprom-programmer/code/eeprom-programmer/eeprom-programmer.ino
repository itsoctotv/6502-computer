#define SHIFT_DATA 2
#define SHIFT_CLK 3
#define SHIFT_LATCH 4
#define EEPROM_D0 5
#define EEPROM_D7 12
#define WRITE_EN 13

#define EEPROM_SIZE 32768
#include "firmware.h"

/*
currently the compiled firmware is being hexdumped and the contents are copied 
into the firmware file which gets flashed onto the arduino the problem with that is 
the arduino nano has a total flash size of 30720 bytes and about 6000bytes are used by the program
but the EEPROM has a size of 32768 bytes that means that only about 14000bytes are usable for EEPROM programming
right now it is just a work around the goal is to have a external micro sd card module and connect it to the arduino 
which allows full EEPROM firmware storage and different versions of firmware (i currently don't have a micro sd card module still WIP)
*/  
/*
 * Output the address bits and outputEnable signal using shift registers.
 */
void setAddress(int address, bool outputEnable) {
  shiftOut(SHIFT_DATA, SHIFT_CLK, MSBFIRST, (address >> 8) | (outputEnable ? 0x00 : 0x80));
  shiftOut(SHIFT_DATA, SHIFT_CLK, MSBFIRST, address);

  digitalWrite(SHIFT_LATCH, LOW);
  digitalWrite(SHIFT_LATCH, HIGH);
  digitalWrite(SHIFT_LATCH, LOW);
}


/*
 * Read a byte from the EEPROM at the specified address.
 */
byte readEEPROM(int address) {
  for (int pin = EEPROM_D0; pin <= EEPROM_D7; pin += 1) {
    pinMode(pin, INPUT);
  }
  setAddress(address, /*outputEnable*/ true);

  byte data = 0;
  for (int pin = EEPROM_D7; pin >= EEPROM_D0; pin -= 1) {
    data = (data << 1) + digitalRead(pin);
  }
  return data;
}


/*
 * Write a byte to the EEPROM at the specified address.
 */
void writeEEPROM(int address, byte data) {
  setAddress(address, /*outputEnable*/ false);
  for (int pin = EEPROM_D0; pin <= EEPROM_D7; pin += 1) {
    pinMode(pin, OUTPUT);
  }

  for (int pin = EEPROM_D0; pin <= EEPROM_D7; pin += 1) {
    digitalWrite(pin, data & 1);
    data = data >> 1;
  }
  digitalWrite(WRITE_EN, LOW);
  delayMicroseconds(1);
  digitalWrite(WRITE_EN, HIGH);
  delay(15);
}


/*
 * Read the contents of the EEPROM and print them to the serial monitor.
 */
void printContents() {
  for (int base = 0; base <= 0x7ff0; base += 16) {
    byte data[16];
    for (int offset = 0; offset <= 15; offset += 1) {
      data[offset] = readEEPROM(base + offset);
    }

    char buf[80];
    sprintf(buf, "%03x:  %02x %02x %02x %02x %02x %02x %02x %02x   %02x %02x %02x %02x %02x %02x %02x %02x",
            base, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7],
            data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]);

    Serial.println(buf);
  }
}


// 4-bit hex decoder for common anode 7-segment display
//byte data[] = { 0x81, 0xcf, 0x92, 0x86, 0xcc, 0xa4, 0xa0, 0x8f, 0x80, 0x84, 0x88, 0xe0, 0xb1, 0xc2, 0xb0, 0xb8 };
//byte data[]={0xea, 0x4c, 0x01,0x02,0x03,0x04};
// 4-bit hex decoder for common cathode 7-segment display
// byte data[] = { 0x7e, 0x30, 0x6d, 0x79, 0x33, 0x5b, 0x5f, 0x70, 0x7f, 0x7b, 0x77, 0x1f, 0x4e, 0x3d, 0x4f, 0x47 };

void eraseEEPROM(){
  for (int address = 0; address < EEPROM_SIZE; address += 1) {
    writeEEPROM(address, 0xff);

    if (address % 64 == 0) {
      Serial.print(".");
      Serial.println(address);

    }
  }
  Serial.println(" done");
}

void writeSingleBytes(){
  writeEEPROM(0xfffc, 0x00);
  writeEEPROM(0xfffd, 0x00);
}

void writeFile(){
  Serial.print("Firmware size: ");
  Serial.println(sizeof(FIRMWARE));

  for(int addr = 0; addr < sizeof(FIRMWARE); addr++){
    writeEEPROM(addr, FIRMWARE[addr]);
    if(addr % 64 == 0){
      Serial.print(".");

    }
  }
  Serial.println("Finished writing to EEPROM");



}
void setup() {

  pinMode(A1, OUTPUT);
  digitalWrite(A1, LOW);
  // put your setup code here, to run once:
  pinMode(SHIFT_DATA, OUTPUT);
  pinMode(SHIFT_CLK, OUTPUT);
  pinMode(SHIFT_LATCH, OUTPUT);
  digitalWrite(WRITE_EN, HIGH);
  pinMode(WRITE_EN, OUTPUT);
  Serial.begin(57600);
  Serial.println("1 = Erase whole EEPROM (will take 5minutes)\n2 = write a single bytes\n3 = Read EEPROM\n4 = Write file\n5 = Exit");

  while(Serial.available() == 0){

  }
  int choice = Serial.parseInt();
  switch(choice){
    case 1:
      Serial.println("Erasing whole EEPROM...");
      eraseEEPROM();
      Serial.println("Done.");
      break;
    case 2:
      Serial.println("Write single bytes...");
      writeSingleBytes();
      Serial.println("Done.");

      break;
    case 3:
      Serial.println("Read whole EEPROM contents...");
      printContents();
      Serial.println("Done.");

      break;
    case 4:
      Serial.println("writing firmware file...");
      writeFile();
      Serial.println("Done.");
      break;
    case 5:
      Serial.println("Aborting");
      break;
    }

}


void loop() {
  // put your main code here, to run repeatedly:
  //blink led after finish writing
  digitalWrite(A1, HIGH);
  delay(500);
  digitalWrite(A1, LOW);
  delay(500);

}
