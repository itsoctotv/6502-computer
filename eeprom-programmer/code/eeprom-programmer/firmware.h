// only < 14000 usable!
#ifndef FIRMWARE_H
#define FIRMWARE_H
// writing from 0x0000 -> the end of the firmware
//
const byte FIRMWARE[] = {
  0x01,
  0x02,
  0x03,
  0x04,
  0xea
};
#endif