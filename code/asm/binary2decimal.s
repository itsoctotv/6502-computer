PORTB = $6000 		; defines for the interface adapter
PORTA = $6001 		; PORTB -> data to the LCD, PORTA -> control for the LCD
DDRB = $6002 		; Data Direction Register B 
DDRA = $6003 		; Data Direction Register A

E  = %10000000 		; Enable Signal
RW = %01000000 		; Read Write Signal
RS = %00100000 		; Register Select Signal

; binary to decimal 
value = $0200		; 2bytes
mod10 = $0202       ; 2bytes
message2 = $0204	; 6bytes










  .org $8000 		; origin of where the code goes in memory 
  
reset:
  ldx #$ff          ; load 0xff to the X register
  txs				; transfer the X register contents to the stack pointer
  					; init the stackpointer to the address FF, the range of the 
  					; stack pointer is 0x100 - 0x1FF  


  
  lda #%11111111 	; init interface adapter, set all PORTB pins to output
  sta DDRB

  lda #%11100001 	; Set top three PORTA pins as output, used to control the LCD
  sta DDRA

  
  ; LCD init----------
  ; RS is LOW -> sending instructions

  
  lda #%00111000 	; Set 8bit mode, 2line display, 5x8 font
  jsr sendLCDInstruction ; jump to subroutine-> send the instruction 
 
  lda #%00001110 	; Set display on, cursor on, blinking cursor off
  jsr sendLCDInstruction
  

  lda #%00000110 	; Increment and shift cursor, don't shift display
  jsr sendLCDInstruction

  lda #%00000001 	; clear display 
  jsr sendLCDInstruction
  


  
  lda #0
  sta message2

; END reset
; BEGIN
; -------

  ; init value to be number to convert, print 16bit counter to LCD
  lda number
  sta value
  lda number + 1
  sta value + 1
divide:
  ; init remainder to be zero
  lda #0
  sta mod10
  sta mod10 + 1
  clc ; clear carry bit


  ldx #16
divloop:
  ; rotate quotient of remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1
  ; A and Y = dividend - divisor
  sec 
  lda mod10
  sbc #10
  tay ; save low byte to Y register
  lda mod10 + 1
  sbc #0
  bcc ignoreResult ; branch if dividend < divisor
  sty mod10 
  sta mod10 + 1
  
  
ignoreResult:
  dex
  bne divloop
  rol value ; shift in the last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr pushCharToString
  ; if value != 0 -> continute dividing
  lda value
  ora value + 1
  bne divide ; branch if value not zero

  
  ; print a string
  ldx #0 			; set the X register to 0, use it as a count
					; at the end of the message .asciiz string there is a 0-byte,
					; which will set the Zero flag when LDA is called -> branch-if-equal -> to the main loop (infinite)
writeMessage:
  lda message2,x		; load char with x register as in msg + 1, msg + 2 etc
  beq loop			
  jsr printCharLCD  
  inx				; increment the x register
  jmp writeMessage

loop:
  jmp loop
  
number: .word 1738

; Add the char in A registor to beginning of null-term string 'message2'
pushCharToString:

  pha ; push new first char onto stack
  ldy #0 
charLoop:
  lda message2,y ; get char string, put into x
  tax
  pla 
  sta message2,y ; pull char off stack and add it to the string
  iny
  txa
  pha			 ; push char from string to stack
  bne charLoop	 
  pla 
  sta message2,y ; pull the null off the stack and add to end of string

  rts


message: .asciiz " 6502-Computer! "




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



  
  .org $fffc
  .word reset       ; set the reset vector
  .word #0000  
