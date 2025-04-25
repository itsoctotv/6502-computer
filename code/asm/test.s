  .org $8000 ; origin of where the code goes in memory 
reset:
  lda #$ff ; init interface adapter
  sta $6002

  lda #%00000001 ; output pattern to A register
  sta $6000 ; load to address 0x6000 where the interface adapter operates

loop:
  ror ; shifts that pattern to the right in the A register
  sta $6000

  jmp loop

  .org $fffc
  .word reset
  .word $0000
