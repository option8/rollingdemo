	DSK SCROLL

**************************************************
* To Do:
*
**************************************************
* Variables
**************************************************

CHAR			EQU		$FC			; char/pixel to plot
TEXTSCROLL1		EQU		$06			; which note to play
TEXTSCROLL2		EQU		$04			; duration of note
TEXTSCROLL3		EQU		$05			; frequency/interclick delay
TEXTSCROLL4		EQU		$03			; ASCII "wave" progress/offset
TEXTSCROLL5		EQU		$02			; "instructions" string offset
TEXTSCROLL6		EQU		$00
TEXTSCROLL7		EQU		$01
TEXTSCROLL8		EQU		$07			; scrolling text offset pixels
TEXTSCROLLEND	EQU		$08			; textscroll + #$28

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
				STA CHAR		
				LDA #$32
				STA TEXTSCROLL1
				STA TEXTSCROLL2
				STA TEXTSCROLL3
				STA TEXTSCROLL4
				STA TEXTSCROLL5
				STA TEXTSCROLL6
				STA TEXTSCROLL7
				STA TEXTSCROLL8
				LDA #$33
				STA TEXTSCROLLEND

DRAWBOARD		JSR HOME			; clears the main text screen
				STA LORES
				
				JSR FILLSCREENFAST
				
				
MAINLOOP
				JSR SCROLLINGTEXT
				
				JMP MAINLOOP				
				


* put scrolling text at $528,$5a8 40 pixels at a time, offset by TEXTSCROLL
SCROLLINGTEXT
				LDY TEXTSCROLL1
				LDX #$00

SCROLLTEXT		LDA SCROLLING,Y
				STA $400,X
				LDA SCROLLING2,Y
				STA $480,X
				INY
				INX
				TXA
				CMP #$28
				BCC SCROLLTEXT		; draw 40 characters across
				
				INC TEXTSCROLL1		; increment offset for next pass
				
				LDA TEXTSCROLL1		; compare offset to 50
				CMP TEXTSCROLLEND
				BEQ SETUPTEXT2
				
				RTS					; return if less than 50 iterations.
				
SETUPTEXT2		LDA #$00	
				STA TEXTSCROLL1		; reset offset if over 50
				INC TEXTSCROLL2		; increment next scroller's offset

		
				LDY TEXTSCROLL2		
				LDX #$00

SCROLLTEXT2		LDA SCROLLING,Y
				CLC
				ADC #$11
				STA $600,X
				LDA SCROLLING2,Y
				CLC
				ADC #$11
				STA $680,X
				INY
				INX
				TXA
				CMP #$28
				BCC SCROLLTEXT2
				
				LDA TEXTSCROLL2		; compare offset to 50
				CMP TEXTSCROLLEND
				BEQ SETUPTEXT3

				RTS
	
SETUPTEXT3		LDA #$00	
				STA TEXTSCROLL2		; reset offset if over 50
				INC TEXTSCROLL3		; increment next scroller's offset

				LDY TEXTSCROLL3		
				LDX #$00

SCROLLTEXT3		LDA SCROLLING,Y
				CLC
				ADC #$22
				STA $428,X
				LDA SCROLLING2,Y
				CLC
				ADC #$22
				STA $4a8,X
				INY
				INX
				TXA
				CMP #$28
				BCC SCROLLTEXT3
				
				LDA TEXTSCROLL3		; compare offset to 50
				CMP TEXTSCROLLEND
				BEQ SETUPTEXT4
				RTS
				
SETUPTEXT4		LDA #$00	
				STA TEXTSCROLL3		; reset offset if over 50
				INC TEXTSCROLL4		; increment next scroller's offset

				LDY TEXTSCROLL4		
				LDX #$00

SCROLLTEXT4		LDA SCROLLING,Y
				CLC
				ADC #$33
				STA $628,X
				LDA SCROLLING2,Y
				CLC
				ADC #$33
				STA $6a8,X
				INY
				INX
				TXA
				CMP #$28
				BCC SCROLLTEXT4
				
				LDA TEXTSCROLL4		; compare offset to 50
				CMP TEXTSCROLLEND
				BEQ SETUPTEXT5
				RTS

SETUPTEXT5		LDA #$00	
				STA TEXTSCROLL4		; reset offset if over 50
				INC TEXTSCROLL5		; increment next scroller's offset

				LDY TEXTSCROLL5		
				LDX #$00

SCROLLTEXT5		LDA SCROLLING,Y
				CLC
				ADC #$44
				STA $450,X
				LDA SCROLLING2,Y
				CLC
				ADC #$44
				STA $4d0,X
				INY
				INX
				TXA
				CMP #$28
				BCC SCROLLTEXT5
				
				LDA TEXTSCROLL5		; compare offset to 50
				CMP TEXTSCROLLEND
				BEQ SETUPTEXT6
				RTS

SETUPTEXT6		LDA #$00	
				STA TEXTSCROLL5		; reset offset if over 50
				INC TEXTSCROLL6		; increment next scroller's offset

				LDY TEXTSCROLL6		
				LDX #$00

SCROLLTEXT6		LDA SCROLLING,Y
				CLC
				ADC #$55
				STA $650,X
				LDA SCROLLING2,Y
				CLC
				ADC #$55
				STA $6d0,X
				INY
				INX
				TXA
				CMP #$28
				BCC SCROLLTEXT6
				
				LDA TEXTSCROLL6		; compare offset to 50
				CMP TEXTSCROLLEND
				BEQ SETUPTEXT7
				RTS

SETUPTEXT7		LDA #$00	
				STA TEXTSCROLL6		; reset offset if over 50
				RTS

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
FILL1 			DEY
				STA $400, Y
				STA $480, Y
				STA $500, Y
				STA $580, Y
				BNE FILL1
				RTS
FILL2 			DEY
				STA $600, Y
				STA $680, Y
				STA $700, Y
				STA $780, Y
				BNE FILL2
				RTS

**************************************************

SCROLLING		HEX	55,05,00,55,05,05,00,55,05,55,00,55,05,55,00,55,00,00,00,55,00,00,00,55,00,55,05,55,00,55,05,05,00,00,05,55,05,00,55,05,05,00,05,50,05,00,05,55,05,00,00,55,05,00,55,05,05,00,55,05,55,00,55,05,55,00,55,00,00,00,55,00,00,00,55,00,55,05,55,00,55,05,05,00,00,05,55,05,00,55,05,05,00,05,50,05,00,05,55,05,00,00
SCROLLING2		HEX	50,55,00,55,50,50,00,55,05,50,00,55,50,55,00,55,50,50,00,55,50,50,00,55,00,55,00,55,00,55,50,55,00,00,00,55,00,00,55,55,50,00,50,05,50,00,00,55,00,00,00,50,55,00,55,50,50,00,55,05,50,00,55,50,55,00,55,50,50,00,55,50,50,00,55,00,55,00,55,00,55,50,55,00,00,00,55,00,00,55,55,50,00,50,05,50,00,00,55,00,00,00
