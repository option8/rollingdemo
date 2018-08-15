	DSK FASTSCAN

**************************************************
* To Do:
*
**************************************************
* Variables
**************************************************

CHAR			EQU		$FC			; char/pixel to plot
DELAY			EQU		$03
DIRECTION		EQU		$02

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
SPEED		EQU		$F1


**************************************************
* START - sets up various fiddly zero page bits
**************************************************
				ORG $2000			; PROGRAM DATA STARTS AT $2000


DRAWBOARD				JSR HOME
						JSR MESSAGE		; 8677 cycles.
						LDA #$11
						STA CHAR
						STA DIRECTION
						STA DELAY
						LDA #$01
						STA SPEED
						JSR FILLSCREENFAST		; 6023 cycles.

* read the VBL
READVBL			BIT RDVBLBAR			; 4
* if bit7 = 0, then VBL active
				BMI READVBL				; 2 wait until refresh interval

* set TEXT during VBL

				STA TXTSET				; 4
				STA TXTPAGE1
	
* read the VBL again
READVBL2		BIT RDVBLBAR			; 4
* if bit7 = 1, then VBL active
				BPL READVBL2			; 2 loop while VBL is happening

* VBL is over 	
* do something while the screen draws a bit
* Screen draws in 12480 instructions

				LDA DIRECTION					; incrementing or decrementing?
				ROR						; bit 0 into Carry	
				BCC INCREMENT			; even = increment, odd = decrement
				
DECREMENT		DEC DELAY					; scan line going up

				STA TXTPAGE1			; show page 1 ( message )
				
				JMP XLOOP				; wait

INCREMENT		INC DELAY					; scan line going down

XLOOP			LDX DELAY
				BEQ NOLOOP
				CPX #$FF
				BEQ NOLOOP
XLOOP2			NOP						; 2		
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2		
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2	
				NOP						; 2		
				NOP						; 2		
				NOP						; 2		
				NOP						; 2		
				NOP						; 2		
				NOP						; 2		
				NOP						; 2		
				DEX						; 2
				BNE XLOOP2				; 2

* set GR at bottom of screen
NOLOOP			STA LORES				; 4
				STA TXTPAGE2
				
				LDA DELAY
				CMP #$C0
				BCS GOFILL				; == C0 change directions	

* loop until the next blank				
GOLOOP			JMP READVBL				


GOFILL			INC DIRECTION				; equal or greater than c0, change colors
				LDA CHAR
				CLC
				ADC #$11
				STA CHAR
				JSR FILLSCREENFAST			; change colors when loop length is >C0
				JMP READVBL

**************************************************
*	writes message
**************************************************
HELLOWORLD		ASC	"Check out what I learned at Kansasfest!",00	; set to ascii for message


MESSAGE	
				LDA #$0B
				STA CV					; jump down
				JSR VTAB
				LDA #$00
				STA CH								
				LDY #>HELLOWORLD
				LDA #<HELLOWORLD
				JSR STROUT				;Y=String ptr high, A=String ptr low

				RTS
;/MESSAGE

**************************************************
*	blanks the screen quickly.
* https://www.atarimagazines.com/compute/issue10/032_1_THE_APPLE_GAZETTE.php
**************************************************
; FOR EACH ROW/COLUMN

FILLSCREENFAST						; 6023 instructions

FLASH 			LDA CHAR			; Get selected color byte
				LDY #$78 			; Prepare to fill 120 bytes
				JSR FILL1			; Fill four sets of 120 bytes each
				LDY #$78 			; Prepare to fill 80 bytes
				JSR FILL2			; Fill four sets of 80 bytes each
				RTS      			; Done. Return.
FILL1 			DEY
				STA $800, Y
				STA $880, Y
				STA $900, Y
				STA $980, Y
				BNE FILL1
				RTS
FILL2 			DEY
				STA $a00, Y
				STA $a80, Y
				STA $b00, Y
				STA $b80, Y
				BNE FILL2
				RTS


