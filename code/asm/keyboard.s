PORTB = $6000 		; defines for the interface adapter
PORTA = $6001 		; PORTB -> data to the LCD, PORTA -> control for the LCD
DDRB = $6002 		; Data Direction Register B 
DDRA = $6003 		; Data Direction Register A
IFR = $600d			; interrupt flags register
IER = $600e			; interrupt enable register
PCR = $600c			; Peripheral control register


E  = %01000000 		; Enable Signal
RW = %00100000 		; Read Write Signal
RS = %00010000 		; Register Select Signal

kbWptr = $0000 		; keyboard write pointer
kbRptr = $0001 		; keyboard read pointer
kbFlags = $0002

RELEASE = %00000001
SHIFT   = %00000010

kbBuffer = $0200 	; 256byte keyboard buffer 0200-02ff in memory




  .org $8000 		; origin of where the code goes in memory 
  
reset:
  ldx #$ff          ; load 0xff to the X register
  txs				; transfer the X register contents to the stack pointer
  					; init the stackpointer to the address FF, the range of the 
  					; stack pointer is 0x100 - 0x1FF  
  
  lda #%00000001	; set rising edge PCR
  sta PCR
  
  lda #%10000010	; Set CA1 interrupt enable
  sta IER

  cli
  
  
  lda #%11111111 	; init interface adapter, set all PORTB pins to output
  sta DDRB

  lda #%00000000 	; Set top three PORTA pins as output, used to control the LCD
  sta DDRA

  
  ; LCD init----------
  ; RS is LOW -> sending instructions

  jsr lcdInit
  lda #%00101000 	; Set 4bit mode; 2line display; 5x8 font
  jsr sendLCDInstruction ; jump to subroutine-> send the instruction 
 
  lda #%00001110 	; Set display on, cursor on, blinking cursor off
  jsr sendLCDInstruction
  

  lda #%00000110 	; Increment and shift cursor, don't shift display
  jsr sendLCDInstruction

  lda #%00000001 	; clear display 
  jsr sendLCDInstruction

  
  lda #$00
  sta kbWptr
  sta kbRptr
  sta kbFlags

; END reset
; BEGIN
; -------

loop:
  sei
  lda kbRptr		; load read pointer value, compare with write pointer value > branch to keypressed otherwise loop through
  cmp kbWptr
  cli
  bne keyPressed
  jmp loop

keyPressed:
  ldx kbRptr		; load Read pointer to X register and use as an index to buffer-> print a char 
  lda kbBuffer, x
  jsr printCharLCD
  inc kbRptr
  jmp loop

  
  ; print a string
  ldx #0 			; set the X register to 0, use it as a count
					; at the end of the message .asciiz string there is a 0-byte,
					; which will set the Zero flag when LDA is called -> branch-if-equal -> to the main loop (infinite)
writeMessage:
  lda message,x		; load char with x register as in msg + 1, msg + 2 etc
  beq loop			
  jsr printCharLCD  
  inx				; increment the x register
  jmp writeMessage

  


message: .asciiz " 6502-Computer! "




checkLCDBusy:
  pha 				; push the given instruction value of the A register to the stack
  lda #%11110000 	; set portB as input
  sta DDRB
lcdBusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB			; read high nibble
  pha				; push to stack because busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       	; Read low nibble
  pla            	; Get high nibble off stack
  and #%00001000	; get the busy flag of LCD
  bne lcdBusy		; stay in the loop while the busy flag is not set

  lda #RW			; clear up 
  sta PORTB

  lda #%11111111 	; set portB to output again
  sta DDRB
  pla 				; pull value off the stack 
  rts

lcdInit:
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB
  rts
  
sendLCDInstruction:
  jsr checkLCDBusy
  pha 
  
  lsr
  lsr
  lsr
  lsr				; send high 4bits
  
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts				; return from subroutine 

printCharLCD:
  jsr checkLCDBusy
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts


irq:			  ; keyboard interrupt handler
  pha
  txa
  pha

  lda kbFlags
  and #RELEASE	  ; check for key releases
  beq readKey	  ; if not read key

  lda kbFlags
  eor #RELEASE	  ; flip release bit
  sta kbFlags
  lda PORTA		  ; read value thats being released
  cmp #$12
  beq shiftUp
  cmp #$59 
  beq shiftUp
  
  jmp exitIR

shiftUp:
  lda kbFlags
  eor #SHIFT	  ; flip shift bit
  sta kbFlags
  jmp exitIR
readKey:
  lda PORTA
  cmp #$f0
  beq keyRelease
  cmp #$12		  ; left shift
  beq shiftDown
  cmp #$59		  ; right shift
  beq shiftDown

  tax
  lda kbFlags
  and #SHIFT
  bne shiftedKey
  
  lda keymap, x	  ; map to char code
  jmp pushKey
  
shiftedKey:
  lda keymapShifted, x	  ; map to char code

pushKey:
  ldx kbWptr
  sta kbBuffer, x
  inc kbWptr
  jmp exitIR
  
shiftDown:
  lda kbFlags
  ora #SHIFT
  sta kbFlags
  jmp exitIR
  
keyRelease:
  lda kbFlags
  ora #RELEASE
  sta kbFlags
exitIR:
  pla 
  tax
  pla
  rti

nmi: 
   rti  

  .org $fe00
keymap:
  .byte "????????????? `?" ; 00-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09==./l;p-?" ; 40-4F
  .byte "??'?[=?????]?\??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

  .org $fd00
keymapShifted:
  .byte "????????????? ~?" ; 00-0F
  .byte "?????Q1???ZSAW@?" ; 10-1F
  .byte "?CXDE#$?? VFTR%?" ; 20-2F
  .byte "?NBHGY^???MJU&*?" ; 30-3F
  .byte "?<KIO)(??>?L:P_?" ; 40-4F
  .byte '??"?{+?????}?|??' ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

  .org $fffa
  .word nmi         ; set non maskable interrupt
  .word reset       ; set the reset vector
  .word irq			; set interrupt request
  
