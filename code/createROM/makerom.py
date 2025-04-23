code = bytearray([
    # setting DDRB (Data Direction Register B from the W65C22 to all output)
    0xa9, 0xff,             # lda #$ff
    0x8d, 0x02, 0x60,       # sta $6002
    
    # write 0x55 (01010101) to the output register B
    0xa9, 0x55,             # lda #$55
    0x8d, 0x00, 0x60,       # sta $6000
    # write 0xaa (10101010) to the output register B
    0xa9, 0xaa,             # lda #$aa
    0x8d, 0x00, 0x60,       # sta $6000
    # jump to the 0x8005 address -> loop it forever
    0x4c, 0x05,0x80,        # jmp $8005
    # --> this will alternate the LEDs (which are connected on Output Port B) on and off
    
])

rom = code + bytearray([0xea] * (32768 - len(code)))


rom[0x7ffc] = 0x00
rom[0x7ffd] = 0x80

with open("rom.bin", "wb") as out_file:
    out_file.write(rom);
