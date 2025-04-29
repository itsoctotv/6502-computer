code = bytearray([
    0xff
    
])

rom = code + bytearray([0xff] * (32768 - len(code)))


rom[0x7ffc] = 0xff
rom[0x7ffd] = 0xff

with open("rom.bin", "wb") as out_file:
    out_file.write(rom);
