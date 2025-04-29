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

  jsr printHelloWorld



loop:
  jmp loop
; -----
; END PROGRAM

  

sendLCDInstruction:
  sta PORTB
  
  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  lda #E 			; Set Enable bit to send instruction
  sta PORTA

  lda #0 			; Clear RS/RW/E bits
  sta PORTA
  rts				; return from subroutine 

printCharLCD:
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  rts

printHelloWorld: 
  ; RS is HIGH -> sending data

  lda #"H"			  ; will automatically load the ascii value
  jsr printCharLCD

  lda #"e"			  
  jsr printCharLCD

  lda #"l"			  
  jsr printCharLCD

  lda #"l"			  
  jsr printCharLCD

  lda #"o"			  
  jsr printCharLCD

  lda #","			  
  jsr printCharLCD

  lda #" "			  
  jsr printCharLCD

  lda #"w"			  
  jsr printCharLCD

  lda #"o"			  
  jsr printCharLCD

  lda #"r"			  
  jsr printCharLCD

  lda #"l"			  
  jsr printCharLCD

  lda #"d"			  
  jsr printCharLCD

  lda #"1"			  
  jsr printCharLCD
  lda #"2"			  
  jsr printCharLCD
  lda #"3"			  
  jsr printCharLCD
  
  rts
  
  .org $fffc ; set the reset vector for the 
  .word reset
  .word $0000
