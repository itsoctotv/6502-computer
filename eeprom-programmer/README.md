# Arduino based EEPROM Programmer
suitable for the AT28C256 EEPROM (possibly its derivitives)  
credits to [here](https://github.com/beneater/eeprom-programmer)
still WIP working on:  
- writing whole firmware files instead of in-code written bytes
- optimization (it takes ~5min to write the whole 256K EEPROM)  

  
´´´
currently the compiled firmware is being hexdumped and the contents are copied 
into the firmware file which gets flashed onto the arduino the problem with that is 
the arduino nano has a total flash size of 30720 bytes and about 6000bytes are used by the program
but the EEPROM has a size of 32768 bytes that means that only about 14000bytes are usable for EEPROM programming
right now it is just a work around the goal is to have a external micro sd card module and connect it to the arduino 
which allows full EEPROM firmware storage and different versions of firmware (i currently don't have a micro sd card module still WIP)  
because of this workaround you need to write the 0xfffc and 0xfffd addresses seperatly with the start address of your code e.g. 0x8000 (for further information look in the datasheet for the 6502 3.11 Reset RESB)  

eeprom address is from 0000 to 7fff but the micro processor sees it as (or talks to it at) from 8000 to ffff because only if the A15 line is active https://youtu.be/yl8vPW5hydQ?si=tGdtmT4nPVF9xE3k&t=589 

´´´
  
 
