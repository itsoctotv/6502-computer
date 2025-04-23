# 6502-computer  
  
Building a 6502 retro style computer    
Mainly with the documentation/schematics and instruction videos of [Ben Eater](https://www.youtube.com/@BenEater)    
Current task is to just getting to know the hardware and software side of it eventually the goal is building a personal computer with actual PCBs (instead of breadboards), extension cards, full display and keyboard functionality. Similar to the Apple 1, Commodore type computers. (which will take a looong time)      

For the EEPROM Programmer (because they cost an arm and a leg) I built the Arduino EEPROM Programmer from Ben Eater code and schematics are [here](https://github.com/beneater/eeprom-programmer) but currently working on having it write a firmware file instead of plainly writing bytes directly in the arduino code. You can find the WIP code and other related things to it [here](eeprom-programmer/) 
    
For monitoring the I/O lines etc. of the 6502 I use a Arduino Mega programmed as a monitor device [here](6502-monitor/) (which is also way cheaper than a logic analyzer).    

For the clock I currently use the [555 style clock](https://eater.net/schematics/clock.png) but later I will be using a 1MHz oscillator clock   

### current task
- waiting for the W65C22 I/O Adapter to arrive and the custom PCBs for the EEPROM programmer

---
_some pics/references can be found [here](docs/misc/)_  


**WIP**   
