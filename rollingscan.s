	DSK ROLLING

**************************************************
* To Do:
*
**************************************************
* Variables
**************************************************

CHAR			EQU		$FC			; char/pixel to plot
SONGOFFSET		EQU		$06			; which note to play
NOTEDURATION	EQU		$04			; duration of note
NOTETONE		EQU		$05			; frequency/interclick delay
WAVECHAR		EQU		$03			; ASCII "wave" progress/offset
STRINGCHAR		EQU		$02			; "instructions" string offset
EVENODD			EQU		$00
SPEED			EQU		$01
TEXTSCROLL		EQU		$07			; scrolling text offset pixels
TEXTSCROLLEND	EQU		$08			; textscroll + #$28
TEXTSCROLLSPEED	EQU		$09			; how often to scroll the text

**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES     EQU   $F832
LORES        EQU   $C050
TXTSET       EQU   $C051
MIXCLR       EQU   $C052
MIXSET       EQU   $C053
TXTPAGE1     EQU   $C054
TXTPAGE2     EQU   $C055
KEY          EQU   $C000
C80STOREOFF  EQU   $C000
C80STOREON   EQU   $C001
STROBE       EQU   $C010
SPEAKER      EQU   $C030
VBL          EQU   $C02E
RDVBLBAR     EQU   $C019       ;not VBL (VBL signal low
WAIT		 EQU   $FCA8 
RAMWRTAUX    EQU   $C005
RAMWRTMAIN   EQU   $C004
SETAN3       EQU   $C05E       ;Set annunciator-3 output to 0
SET80VID     EQU   $C00D       ;enable 80-column display mode (WR-only)
HOME 		 EQU   $FC58			; clear the text screen
CH           EQU   $24			; cursor Horiz
CV           EQU   $25			; cursor Vert
VTAB         EQU   $FC22       ; Sets the cursor vertical position (from CV)
COUT         EQU   $FDED       ; Calls the output routine whose address is stored in CSW,
                               ;  normally COUTI
STROUT		 EQU   $DB3A 		;Y=String ptr high, A=String ptr low

ALTTEXT		 EQU	$C055
ALTTEXTOFF   EQU	$C054

ROMINIT      EQU    $FB2F
ROMSETKBD    EQU    $FE89
ROMSETVID    EQU    $FE93

ALTCHAR		EQU		$C00F		; enables alternative character set - mousetext

BLINK		EQU		$F3




				ORG $2000			; PROGRAM DATA STARTS AT $2000


**************************************************
* START - sets up various fiddly zero page bits
**************************************************

				LDA #$00			; reset the string and wave offsets for drawing text
				STA STRINGCHAR
				STA CHAR		
				STA SONGOFFSET	
				STA NOTEDURATION
				STA NOTETONE	
				STA STRINGCHAR	
				STA EVENODD		
				STA $F1
				STA TEXTSCROLL
				LDA #$26
				STA WAVECHAR
				STA SPEED
				LDA #$33
				STA TEXTSCROLLEND
				LDA #$04
				STA TEXTSCROLLSPEED

**************************************************
DRAWBOARD		JSR HOME			; clears the main text screen
				JSR FILLSCREENFAST

* I'm reading in $C019, which, if I'm understanding what I've seen, bit 7 will go high when the VBL is active.
* If I want to split the screen, I can wait for the VBL to happen, set text mode. Wait again until the VBL is done, 
* twiddle a little bit, then set GR mode. Depending on how long i twiddle, there will be some text at the top of the screen 
* and low res on the bottom.

**************************************************
* SET UP MUSIC
				LDY #$00
				STY SONGOFFSET				; current position in the score
				LDA DURATIONS,Y				; 	*60ths of a second duration		
				STA NOTEDURATION			; 	$04 sound duration
				LDA TONES,Y					
				STA NOTETONE				;  	$05 tone value

**************************************************
* MAIN LOOP
**************************************************


* WAITING FOR VBL
READVBL			LDX NOTETONE				;	2
TONELOOP2		DEX							;	2		WAITS BETWEEN CLICKS
				BNE TONELOOP2				;	4 not taken, 2 taken
				STA SPEAKER					;	4		CLICKS
BITVBL			BIT RDVBLBAR				; 	4
											* if bit7 = 0, then VBL active
				BMI READVBL					; 	2 wait until refresh interval


* VBL STARTED - BLANK SCREEN

				LDA NOTEDURATION			; if duration has counted down to zero,
				BEQ NEXTNOTE				; skip to next note
				DEC NOTEDURATION			; otherwise, decrement sound duration
				JMP SOUNDDONE				
NEXTNOTE		
* LDY the current note's position	
				LDA NOTETONE
* if note == 0, start over
				BNE LOADNOTE
				LDA #$FF
				STA SONGOFFSET				; set $06 to 0, JMP NEXTNOTE
LOADNOTE		LDA SONGOFFSET
				TAY
				INY
				STY SONGOFFSET
* LDA the next note in the "Score" 
* store it at $05
				LDA TONES,Y
				STA NOTETONE
* LDA the next note's duration
* store it at $04
				LDA DURATIONS,Y
				STA NOTEDURATION


SOUNDDONE
* roll through colors 2 6 A F, fills top third of screen
				LDY SPEED
				LDA BLUES,Y
				STA CHAR
				JSR FILLTOP				; 1804 instructions

				JSR INSTRUCTIONSFAST	; way faster than STROUT or COUT.
				JSR WAVETEXT			; plot one character of ASCII "wave" animation.



WHITEBARS
; bottom 4 lines
; 650
; 6d0
; 750
; 7d0	
				LDA SPEED
				TAY				
				LDA #$20				; inverse space
				STA $650,Y
				INY
				LDA #$A0
				STA $650,Y

				LDA SPEED
				LSR
				TAY				
				LDA #$20				; inverse space
				STA $6D0,Y
				INY
				LDA #$A0
				STA $6D0,Y

				LDA SPEED
				LSR
				LSR
				TAY				
				LDA #$20				; inverse space
				STA $750,Y
				INY
				LDA #$A0
				STA $750,Y

				LDA SPEED
				LSR
				LSR
				LSR
				TAY				
				LDA #$20				; inverse space
				STA $7D0,Y
				INY
				LDA #$A0
				STA $7D0,Y


SETTEXTMODE

* set TEXTMODE *during* VBL

				STA TXTSET				; 4
				STA TXTPAGE1



	
* read the VBL again
READVBL2		BIT RDVBLBAR			; 4
* if bit7 = 1, then VBL active
				BPL READVBL2			; 2 loop while VBL is happening

* Vertical blank is 4550 cycles.
* I'm using ~ 4396

**************************************************
* VBL DONE - DRAWING SCREEN NOW
**************************************************

* VBL is over 	
* do something while the screen draws a bit
* Screen draws in 12480 instructions = 192 lines * 65 instructions/lines

				STA ALTTEXTOFF
* show the main text page, with instructions				
				

* varying delay gives us a rolling effect
				JSR WAITABIT
* show color bars
				STA LORES
				STA ALTTEXT

* wait a bit while screen draws small slice of color bars
				LDY #$10
				JSR SCROLLINGTEXT		;	Y = $10 == 1081 / 65 ~ 16.5 scanlines between LORES and TXTSET

* back to text page
				STA TXTSET				; 4
				STA TXTPAGE1			; 1269 - 3868 cycles to this point. Varies with WAITABIT

* < 4000 cycles to here. I have 8000 or so to play around with. Let there be sound! 
* sound processing and beeps all happen at the READVBL stage, while waiting for the screen to finish drawing.
				
				LDA #$1F
				SEC
				SBC SPEED
				TAY
				JSR ROLLINGDELAY		; 65 instructions per scanline?
				STA LORES
				LDY #$1F
				JSR ROLLINGDELAY		; 65 instructions per scanline?
				STA TXTSET				

* loop until the next blank				
GOLOOP			JMP READVBL				
**************************************************





**************************************************
*	The actual fun part:
*	delay loop that increases, then decreases
**************************************************

WAITABIT		DEC WAVECHAR					
				BMI RELOAD				; shouldn't ever get below zero

				LDA WAVECHAR			; move ascii wave in from right
				CMP STRINGCHAR
				BEQ RELOAD				; roll offset until same as character being added
				BCC RELOAD				; roll too far? quit that.
				JMP LOADSPEED
* decrement WAVECHAR until it reaches STRINGCHAR, then set it back to #$27

RELOAD			LDA #$27
				STA WAVECHAR				
LOADSPEED		LDA SPEED				; if speed is zero
				CMP #$01
				BEQ SETODD				; set even/odd to odd (1)

				CMP #$1E				; otherwise if speed is >20, set even
				BCC EVENORODD			; if less than 20 continue doing what you've been doing

SETEVEN			LDA #$00				
				STA EVENODD				; set to even (0)

				LDA STRINGCHAR
				CMP #$26
				BEQ EVENORODD
				INC STRINGCHAR			; characters of the text to display
				JMP EVENORODD

SETODD			LDA #$01				
				STA EVENODD				; set even/odd to odd (1)

				LDA STRINGCHAR
				CMP #$26
				BEQ EVENORODD
				INC STRINGCHAR			; characters of the text to display
				
EVENORODD		LDA EVENODD				; load even/odd
				BNE INCSPEED			; if odd (not zero) then start increasing delay
				
DECSPEED		DEC SPEED				; otherwise, decrease the delay
				LDY SPEED	
				JSR ROLLINGDELAY
				RTS

INCSPEED		INC SPEED
				LDY SPEED
				JSR ROLLINGDELAY
				RTS



**************************************************
*	writes message directly to $600
*	much faster than using ROM routines for strout.
**************************************************

INSTRUCTIONSFAST							; 547 cycles.
				LDY STRINGCHAR				; characters of string, increments up to #$26
CHAROUT			LDA HELLOWORLD,Y
CHARFILL		STA $600,Y
				RTS

;/INSTRUCTIONSFAST


**************************************************
* scroll "wave" character in from right.
**************************************************


WAVETEXT		LDY WAVECHAR				; where is the wave? decrements from #$27 to STRINGCHAR

* start at #$27
* $600,Y = DINGBATS,Y
LOADWAVE		LDA DINGBATS,Y
				STA $600,Y
				INY
* $600,Y = SPACES,Y - to erase previous DINGBAT
				LDA #$A0
				STA $600,Y
				RTS
;/WAVETEXT


**************************************************
*	short delay - gets loop counts from Y
**************************************************
ROLLINGDELAY							
										 
YLOOP			TYA						;	
				TAX						;	
										;	
XLOOP			DEX						;	
				BNE XLOOP				;	
				
				NOP 					;	
				NOP						;
				NOP						;
				NOP						;
				NOP						;
				NOP						;
				NOP						;
				NOP						;	
				
				DEY						;	
				BNE YLOOP				;	
				
				RTS						;	


**************************************************
* put scrolling text at $528,$5a8 40 pixels at a time, offset by TEXTSCROLL
**************************************************
SCROLLINGTEXT
				LDY TEXTSCROLL
				LDX #$04
SCROLLTEXT		LDA SCROLLING,Y
				STA $4a8,X
				LDA SCROLLING2,Y
				STA $528,X
				INY
				INX
				CPX #$24
				BCC SCROLLTEXT			; do this 32 times
				

				DEC TEXTSCROLLSPEED
				BEQ INCSCROLL
				
				LDA TEXTSCROLL
				CMP TEXTSCROLLEND
				BNE DONESCROLL
				
				LDA #$00
				STA TEXTSCROLL
DONESCROLL		RTS

INCSCROLL		INC TEXTSCROLL
				LDA #$04
				STA TEXTSCROLLSPEED
				RTS



**************************************************
*	blanks the top third of the alttext screen quickly.
*	fill color from CHAR
**************************************************
FILLTOP						

	 			LDA CHAR			; Get selected color byte
				LDY #$28 			; #$78 Prepare to fill 120 bytes

FILLTOP1 		DEY
				STA $800, Y
				STA $880, Y
				STA $900, Y
				STA $980, Y
				STA $a00, Y
				STA $a80, Y
				STA $b00, Y
				STA $b80, Y
				BNE FILLTOP1
				RTS      			; Done. Return.


**************************************************
*	blanks the screen quickly.
* https://www.atarimagazines.com/compute/issue10/032_1_THE_APPLE_GAZETTE.php
**************************************************
FILLSCREENFAST						; 6023 instructions

FLASH 			LDA CHAR			; Get selected color byte
				LDY #$78 			; #$78 Prepare to fill 120 bytes
				JSR FILL1			; Fill four sets of 120 bytes each
				LDY #$78 			; Prepare to fill 80 bytes
				JSR FILL2			; Fill four sets of 80 bytes each
				RTS      			; Done. Return.
  ; Subroutine FILL1 puts the selected color byte into
  ; each of four sets of 120 consecutive screen-memory
  ; bytes, being careful to avoid the scratchpad bytes at
  ; the end of each set.
FILL1 			DEY
				STA $800, Y
				STA $880, Y
				STA $900, Y
				STA $980, Y
				BNE FILL1
				RTS
   ; Subroutine FILL2 puts the selected color byte into each
   ; of four sets of 80 consecutive screen-memory bytes.
   ; These are the "short lines", leaving out at the end of
   ; each one of the four text lines at the bottom of the
   ; mixed screen.
FILL2 			DEY
				STA $a00, Y
				STA $a80, Y
				STA $b00, Y
				STA $b80, Y
				BNE FILL2
				RTS

**************************************************

HELLOWORLD		ASC	"Check out what I learned at Kansasfest!  ",00	; set to ascii for message
DINGBATS		ASC	"!/-\!/-\!/-\!/-\!/-\!/-\!/-\!/-\!/-\!/-  ",00	; ascii wave

* rolling color bars
BLUES			HEX	11,11,11,11,b1,1b,b1,1b,b1,1b,b1,1b,eb,be,eb,be,ec,ce,ec,ce,ec,ce,cc,cc,cc,cc,c4,4c,c4,4c,44,44


* test tones
;TONES			HEX F0,80,40,20,10,08,04,00
;DURATIONS		HEX 4B,4B,4B,4B,4B,4B,4B,00

* DAISY BELL
;TONES			HEX	71,86,A9,e1,C9,B3,A9,C9,A9,e1,96,71,86,A9,C9,B3,A9,96,86,96,01,86,77,86,96,71,86,96,A9,96,86,A9,C9,A9,C9,e1,E1,A9,86,96,01,A9,86,96,01,86,77,71,86,A9,96,e1,A9,01,00
;DURATIONS		HEX	30,30,30,30,10,10,10,20,10,60,30,30,30,30,10,10,10,20,10,40,10,10,10,10,10,20,10,10,40,10,20,10,20,10,10,40,10,20,10,10,20,20,10,10,10,05,05,10,10,10,20,10,40,FF,00 

*Bb SCALE
;TONES			HEX A9,96,86,7E,71,64,59,54,59,64,71,7E,86,96,A9,A9,86,71,54,71,86,A9,00
;DURATIONS		HEX	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,00

*OOM-PAH
;TONES			HEX	A9,54,A9,54,71,A9,86,71,A9,54,A9,54,71,71,86,96,A9,54,A9,54,A9,A9,86,71,A9,54,A9,54,A9,00
;DURATIONS		HEX 10,10,10,10,10,05,05,05,10,10,10,10,10,05,05,05,10,10,10,10,10,05,05,05,10,10,10,10,40,00

TONES			HEX	EF,77,64,C9,FF,C9,FF,C9
				HEX	59,64,EF,C9,FF,C9,FF,B3
				HEX	EF,77,64,C9,FF,C9,FF,C9
				HEX	59,64,EF,C9,FF,C9,FF,B3
				HEX	EF,77,64,C9,FF,C9,FF,C9 
				HEX	59,64,EF,C9,FF,C9,FF,B3
				HEX	EF,77,64,C9,FF,C9,FF,C9
				HEX	59,64,EF,C9,FF,C9,FF,B3,00

DURATIONS		HEX	05,05,05,05,05,05,05,15
				HEX	05,05,05,05,05,05,05,15	
				HEX	05,05,05,05,05,05,05,15
				HEX	05,05,05,05,05,05,05,15
				HEX	05,05,05,05,05,05,05,15
				HEX	05,05,05,05,05,05,05,15
				HEX	05,05,05,05,05,05,05,15
				HEX	05,05,05,05,05,05,05,15,00

SCROLLING		HEX	FF,0F,00,FF,0F,0F,00,FF,0F,FF,00,FF,0F,FF,00,FF,00,00,00,FF,00,00,00,FF,00,FF,0F,FF,00,FF,0F,0F,00,00,0F,FF,0F,00,FF,0F,0F,00,0F,F0,0F,00,0F,FF,0F,00,00,FF,0F,00,FF,0F,0F,00,FF,0F,FF,00,FF,0F,FF,00,FF,00,00,00,FF,00,00,00,FF,00,FF,0F,FF,00,FF,0F,0F,00,00,0F,FF,0F,00,FF,0F,0F,00,0F,F0,0F,00,0F,FF,0F,00,00
SCROLLING2		HEX	F0,FF,00,FF,F0,F0,00,FF,0F,F0,00,FF,F0,FF,00,FF,F0,F0,00,FF,F0,F0,00,FF,00,FF,00,FF,00,FF,F0,FF,00,00,00,FF,00,00,FF,FF,F0,00,F0,0F,F0,00,00,FF,00,00,00,F0,FF,00,FF,F0,F0,00,FF,0F,F0,00,FF,F0,FF,00,FF,F0,F0,00,FF,F0,F0,00,FF,00,FF,00,FF,00,FF,F0,FF,00,00,00,FF,00,00,FF,FF,F0,00,F0,0F,F0,00,00,FF,00,00,00
				