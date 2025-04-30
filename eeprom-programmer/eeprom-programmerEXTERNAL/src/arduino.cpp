/*
 * AT28C256 EEPROM Reader and Programmer
 *
 * Pin Layout
 *
 * Pin | Circuit
 * ----+--------------
 *   2 | EEPROM IO0
 *   3 | EEPROM IO1
 *   4 | EEPROM IO2
 *   5 | EEPROM IO3
 *   6 | EEPROM IO4
 *   7 | EEPROM IO5
 *   8 | EEPROM IO6
 *   9 | EEPROM IO7
 * ----+--------------
 *  A3 | 74HC595 OE
 *  A4 | 74HC595 SER
 * 11  | 74HC595 SCLK
 * 12  | 74HC595 RCLK
 * 13  | 74HC595 CLR
 * ----+--------------
 *  A0 | EEPROM WE
 *  A1 | EEPROM OE
 *  A2 | EEPROM CE
 * ----+--------------
 * 10  | Activity LED
 */

#include <Arduino.h>

enum MODE {STANDBY, READ, WRITE};
typedef enum {
  OK,
  E_RESET,
  E_CORRUPT,
  E_UNEXPECTED,
  E_UNKNOWN
} error;

const unsigned int MAX_PAYLOAD = 63;
const unsigned int DELAY_US    = 10;

// AT28C256 control lines
const unsigned int EEPROM_WE = A0;
const unsigned int EEPROM_OE = A1;
const unsigned int EEPROM_CE = A2;

// 74HC595 control lines
const unsigned int SHIFT_OE   = A3;
const unsigned int SHIFT_SER  = A4;
const unsigned int SHIFT_SCLK = 11;
const unsigned int SHIFT_RCLK = 12;
const unsigned int SHIFT_CLR  = 13;

// Activity LED
const unsigned int ACT_LED = 10;

// Data pins (LSB to MSB)
const unsigned int dataPins[] = {2,3,4,5,6,7,8,9};

MODE mode = STANDBY;
error errnoState = OK;

int receive(byte *buf, size_t len, bool sendAck);
int sendData(byte *buf, size_t len, bool waitForAck);
void pulse(int pin);
void loadShiftAddr(unsigned int addr);
byte readAddr(unsigned int addr);
void writeAddr(unsigned int addr, byte val);
int dumpEEPROM();
int loadEEPROM(unsigned int len);
int writeMode();
int readMode();
int standbyMode();
void processError();

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(120000L);

  pinMode(EEPROM_CE, OUTPUT);
  pinMode(EEPROM_OE, OUTPUT);
  pinMode(EEPROM_WE, OUTPUT);

  pinMode(SHIFT_OE, OUTPUT);
  pinMode(SHIFT_SER, OUTPUT);
  pinMode(SHIFT_SCLK, OUTPUT);
  pinMode(SHIFT_RCLK, OUTPUT);
  pinMode(SHIFT_CLR, OUTPUT);

  digitalWrite(SHIFT_OE, LOW);
  digitalWrite(SHIFT_CLR, HIGH);

  pinMode(ACT_LED, OUTPUT);
  digitalWrite(ACT_LED, LOW);

  standbyMode();
}

int receive(byte *buf, size_t len, bool sendAck) {
  int l;
  do { l = Serial.read(); } while (l == -1);
  if (l > 0) {
    if (Serial.readBytes(buf, min((size_t)l, len)) != l) {
      errnoState = E_CORRUPT;
      return -1;
    }
  }
  if (sendAck && sendData(NULL, 0, false) == -1) {
    return -1;
  }
  return l;
}

int sendData(byte *buf, size_t len, bool waitForAck) {
  Serial.write((uint8_t)len);
  if (len > 0) Serial.write(buf, len);
  if (waitForAck) {
    byte ackBuf[1 + MAX_PAYLOAD];
    int l = receive(ackBuf, MAX_PAYLOAD, false);
    if (l != 0) {
      if (l == 1 && ackBuf[0] == 'r') errnoState = E_RESET;
      else if (l != -1) errnoState = E_UNEXPECTED;
      return -1;
    }
  }
  return 0;
}

void pulse(int pin) {
  digitalWrite(pin, HIGH);
  delayMicroseconds(DELAY_US);
  digitalWrite(pin, LOW);
  delayMicroseconds(DELAY_US);
}

void loadShiftAddr(unsigned int addr) {
  digitalWrite(SHIFT_CLR, HIGH);
  digitalWrite(SHIFT_RCLK, LOW);
  for (int i = 15; i >= 0; i--) {
    digitalWrite(SHIFT_SER, (addr >> i) & 1);
    delayMicroseconds(DELAY_US);
    pulse(SHIFT_SCLK);
  }
  delayMicroseconds(DELAY_US);
  pulse(SHIFT_RCLK);
}

byte readAddr(unsigned int addr) {
  readMode();
  loadShiftAddr(addr);
  delayMicroseconds(DELAY_US);

  byte val = 0;
  for (unsigned int i = 0; i < 8; i++) {
    val |= digitalRead(dataPins[i]) << i;
  }
  standbyMode();
  return val;
}

void writeAddr(unsigned int addr, byte val) {
  loadShiftAddr(addr);
  writeMode();

  for (unsigned int i = 0; i < 8; i++) {
    digitalWrite(dataPins[i], (val >> i) & 1);
  }
  delayMicroseconds(DELAY_US);
  digitalWrite(EEPROM_WE, LOW);
  delayMicroseconds(DELAY_US);
  digitalWrite(EEPROM_WE, HIGH);

  // Poll D7 toggle-bit
  readMode();
  byte bus;
  do {
    bus = 0;
    for (unsigned int i = 0; i < 8; i++) {
      bus |= digitalRead(dataPins[i]) << i;
    }
  } while ((bus & 0x80) != (val & 0x80));

  standbyMode();
}

int dumpEEPROM() {
  byte payload[MAX_PAYLOAD];
  unsigned int idx = 0;
  for (unsigned int addr = 0; addr < 32768; addr++) {
    if (idx == MAX_PAYLOAD) {
      if (sendData(payload, MAX_PAYLOAD, true) == -1) return -1;
      idx = 0;
    }
    payload[idx++] = readAddr(addr);
  }
  if (idx) return sendData(payload, idx, true);
  return 0;
}

int loadEEPROM(unsigned int len) {
  unsigned int addr = 0;
  byte buf[1 + MAX_PAYLOAD];
  while (addr < len) {
    int cnt = receive(buf, sizeof(buf), true);
    if (cnt == -1) return -1;
    for (int i = 0; i < cnt; i++) {
      writeAddr(addr++, buf[i]);
    }
  }
  return 0;
}

int writeMode() {
  digitalWrite(EEPROM_CE, LOW);
  digitalWrite(EEPROM_OE, HIGH);
  digitalWrite(EEPROM_WE, HIGH);
  for (unsigned int i = 0; i < 8; i++) pinMode(dataPins[i], OUTPUT);
  delayMicroseconds(DELAY_US);
  mode = WRITE;
  return 0;
}

int readMode() {
  if (mode != READ) {
    for (unsigned int i = 0; i < 8; i++) pinMode(dataPins[i], INPUT);
    digitalWrite(EEPROM_CE, LOW);
    digitalWrite(EEPROM_OE, LOW);
    digitalWrite(EEPROM_WE, HIGH);
    delayMicroseconds(DELAY_US);
    mode = READ;
  }
  return 0;
}

int standbyMode() {
  for (unsigned int i = 0; i < 8; i++) pinMode(dataPins[i], INPUT);
  digitalWrite(EEPROM_OE, LOW);
  digitalWrite(EEPROM_CE, HIGH);
  digitalWrite(EEPROM_WE, HIGH);
  delayMicroseconds(DELAY_US);
  mode = STANDBY;
  return 0;
}

void processError() {
  if (errnoState != OK) {
    for (int i = 0; i < 5; i++) {
      digitalWrite(ACT_LED, HIGH);
      delay(100);
      digitalWrite(ACT_LED, LOW);
      delay(100);
    }
    errnoState = OK;
  }
}

void loop() {
  if (Serial.available() > 0) {
    byte cmdBuf[1 + MAX_PAYLOAD];
    digitalWrite(ACT_LED, HIGH);
    int len = receive(cmdBuf, sizeof(cmdBuf), false);
    if (len > 0) {
      if (cmdBuf[0] == 0x72 && len == 3) {
        byte v = readAddr((cmdBuf[1] << 8) + cmdBuf[2]);
        sendData(&v, 1, false);
      } else if (cmdBuf[0] == 0x77 && len == 4) {
        writeAddr((cmdBuf[1] << 8) + cmdBuf[2], cmdBuf[3]);
        sendData(NULL, 0, false);
      } else if (cmdBuf[0] == 0x64 && len == 1) {
        dumpEEPROM();
      } else if (cmdBuf[0] == 0x6c && len == 3) {
        sendData(NULL, 0, false);
        loadEEPROM((cmdBuf[1] << 8) + cmdBuf[2]);
      } else {
        errnoState = E_UNKNOWN;
      }
    }
    digitalWrite(ACT_LED, LOW);
  }
  processError();
}
