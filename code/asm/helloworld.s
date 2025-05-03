PORTB = $6000 		; defines for the interface adapter
PORTA = $6001 		; PORTB -> data to the LCD, PORTA -> control for the LCD
DDRB = $6002 		; Data Direction Register B 
DDRA = $6003 		; Data Direction Register A

E  = %10000000 		; Enable Signal
RW = %01000000 		; Read Write Signal
RS = %00100000 		; Register Select Signal

  .org $8000 		; origin of where the code goes in memory 
  
reset:
  ldx #$ff          ; load 0xff to the X register
  txs				; transfer the X register contents to the stack pointer
  					; init the stackpointer to the address FF, the range of the 
  					; stack pointer is 0x100 - 0x1FF  


  
  lda #%11111111 	; init interface adapter, set all PORTB pins to output
  sta DDRB

  lda #%11100000 	; Set top three PORTA pins as output, used to control the LCD
  sta DDRA

  
  ; LCD init----------
  ; RS is LOW -> sending instructions

  
  lda #%00111000 	; Set 8bit mode, 2line display, 5x8 font
  jsr sendLCDInstruction ; jump to subroutine-> send the instruction 
 
  lda #%00001110 	; Set display on, cursor on, blinking cursor off
  jsr sendLCDInstruction
  

  lda #%00000110 	; Increment and shift cursor, don't shift display
  jsr sendLCDInstruction

  lda #%00000001 	; clear display when reset
  jsr sendLCDInstruction

; END reset
; BEGIN
; -------



  ldx #0 			; set the X register to 0, use it as a count
					; at the end of the message .asciiz string there is a 0-byte,
					; which will set the Zero flag when LDA is called -> branch-if-equal -> to the main loop (infinite)
writeMessage:
  lda message,x		; load char with x register as in msg + 1, msg + 2 etc
  beq loop			
  jsr printCharLCD  
  inx				; increment the x register
  jmp writeMessage



loop:
  jmp loop
; -----
; END PROGRAM


message: .asciiz "  Hello World!                           6502-Computer!"




checkLCDBusy:
  pha 				; push the given instruction value of the A register to the stack
  lda #%00000000 	; set portB as input
  sta DDRB
lcdBusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000	; get the busy flag of LCD
  bne lcdBusy		; stay in the loop while the busy flag is not set

  lda #RW			; clear up 
  sta PORTA

  lda #%11111111 	; set portB to output again
  sta DDRB
  pla 				; pull value off the stack 
  rts


sendLCDInstruction:
  jsr checkLCDBusy
  sta PORTB
  
  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  lda #E 			; Set Enable bit to send instruction
  sta PORTA

  lda #0 			; Clear RS/RW/E bits
  sta PORTA
  rts				; return from subroutine 

printCharLCD:
  jsr checkLCDBusy
  sta PORTB
    ; RS is HIGH -> sending data

  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  rts

  .org $fffc ; set the reset vector for the 
  .word reset
  .word $0000
