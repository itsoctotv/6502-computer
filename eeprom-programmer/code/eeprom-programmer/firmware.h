// only < 14000 usable!
#ifndef FIRMWARE_H
#define FIRMWARE_H
// writing from 0x0000 -> the end of the firmware
//
const byte FIRMWARE[] = {
  0xa9, // load emidiate in to A Register
  0x42, // value 42
  0x8d, // store it at A register
  0x00, // at address
  0x60  // 6000
};
#endif