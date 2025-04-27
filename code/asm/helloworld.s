PORTB = $6000 		; defines for the interface adapter
PORTA = $6001 		; PORTB -> data to the LCD, PORTA -> control for the LCD
DDRB = $6002 		; Data Direction Register B 
DDRA = $6003 		; Data Direction Register A

E  = %10000000 		; Enable Signal
RW = %01000000 		; Read Write Signal
RS = %00100000 		; Register Select Signal

  .org $8000 		; origin of where the code goes in memory 
reset:
  lda #%11111111 	; init interface adapter, set all PORTB pins to output
  sta DDRB

  lda #%11100000 	; Set top three PORTA pins as output, used to control the LCD
  sta DDRA
  ; LCD init----------
  ; RS is LOW -> sending instructions
  lda #%00111000 	; Set 8bit mode, 2line display, 5x8 font
  sta PORTB
  
  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  lda #E 			; Set Enable bit to send instruction
  sta PORTA

  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  
  lda #%00001111 	; Set display on, cursor on, blinking cursor on
  sta PORTB
  
  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  lda #E 			; Set Enable bit to send instruction
  sta PORTA

  lda #0 			; Clear RS/RW/E bits
  sta PORTA
  

  lda #%00000110 	; Increment and shift cursor, don't shift display
  sta PORTB
  
  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  lda #E 			; Set Enable bit to send instruction
  sta PORTA

  lda #0 			; Clear RS/RW/E bits
  sta PORTA

  ; RS is HIGH -> sending data

  lda #"H"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA

  lda #"e"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA

  lda #"l"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"l"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"o"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #","			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #" "			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"w"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"o"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"r"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"l"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"d"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA
  lda #"!"			; will load the ascii value automatically 
  sta PORTB
  
  lda #RS 			; set RS bit 
  sta PORTA

  lda #(RS | E) 	; Set Enable bit to send instruction and set RS bit
  sta PORTA

  lda #RS 			; set RS bit
  sta PORTA


loop:
  jmp loop



 
  .org $fffc ; set the reset vector for the 
  .word reset
  .word $0000
