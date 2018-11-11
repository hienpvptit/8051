RS BIT P3.6
EN BIT P3.7

; Cac bien phuc vu cho chuong trinh dem xung
TMP_COUNT EQU 30H 		; Bien dem luu tru tam thoi
COUNT EQU 31H			; So vong trong mot giay
PULSE_RM_H EQU 32H 		; So xung con lai - 8 bit cao
PULSE_RM_L EQU 33H		; So xung con lai - 8 bit thap 
TMP_TH1 EQU 34H			; Bien luu tru TH1 tam thoi
TMP_TL1 EQU 35H			; Bien luu tru TL1 tam thoi
COUNT_ET0 EQU 36H		; Bien dem trong Timer 0

; Cac bien phuc vu cho chuong trinh chia 2 so 16 bit
SUBB1_H EQU 37H			; 8 bit cao so bi tru		
SUBB1_L EQU 38H			; 8 bit thap so bi tru
SUBB2_H EQU 39H			; 8 bit cao so tru
SUBB2_L EQU 3AH			; 8 bit thap so tru
SUBB_RS_H EQU 3BH		; 8 bit cao ket qua
SUBB_RS_L EQU 3CH		; 8 bit thap ket qua

DIV_RS EQU 3DH			; Thuong cua phep chia
DIV_RM EQU 3EH			; So du cua phep chia

; Cac bien phuc vu cho chuong trinh nhan so 16 bit voi so 8 bit
; Dieu kien: So 16bit < 334; So 8 bit = 60
MUL1_H EQU 3FH			; 8 bit cao thua so 1
MUL1_L EQU 40H			; 8 bit thap thua so 1
MUL2   EQU 41H			; Thua so 2

	; 16 bit ket qua
ADD1_H EQU 42H
ADD1_L EQU 43H
ADD2_H EQU 44H
ADD2_L EQU 45H
ADD_RS_H EQU 46H
ADD_RS_L EQU 47H

MUL_RS_H EQU 48H		
MUL_RS_L EQU 49H		

; Cac bien luu ket qua
RPM_H EQU 4AH
RPM_L EQU 4BH


; Chuong trinh	chinh
ORG 00H
LJMP MAIN

; Dia chia ngat timer 0
ORG 0BH
LJMP ISR_ET0

; Dia chi ngat timer 1
ORG 1BH
LJMP ISR_ET1

; Dia chi chuong trinh chinh
ORG 30H
MAIN:
		; LCD INIT
	MOV A, #38H			; LCD1602
	CALL LCD_WR_CMD
	MOV A, #0CH			; TURN ON LCD
	CALL LCD_WR_CMD
	MOV A, #1H			; CLEAR LCD
	CALL LCD_WR_CMD

	; Timer
	MOV TMOD, #51H		; Timer 0, Mode 1;  Timer 1, mode 1 C/T=1
	MOV TL1, #0B2H		; Count 334 pulse
	MOV TH1, #0FEH
	SETB ET1			; Enable interrupt timer 1
	MOV TMP_COUNT, #0
	MOV COUNT, #0
	
	MOV TL0, #0F0H		; 10 ms
	MOV TH0, #0D8H
	SETB ET0		    ; Enable interrupt timer 0
	MOV COUNT_ET0, #99	; 10 ms x 100 = 1s
	
	SETB EA				; Enable interrupt

	SETB TR0			; Start timer 0
	SETB TR1			; Start timer 1

MAIN_LOOP:
	CALL CALCULATOR
	CALL SHOW
	MOV R7, #200
	CALL DELAY
	MOV R7, #200
	CALL DELAY

	JMP MAIN_LOOP

CALCULATOR:
	; RPM = vong/s * 60 + ((xungdu*60) /334)
	MOV SUBB1_L, TMP_TL1
	MOV	SUBB1_H, TMP_TH1
	MOV SUBB2_L, #0B2H
	MOV SUBB2_H, #0FEH
	CALL SUBB16
	MOV MUL1_L, SUBB_RS_L
	MOV MUL1_H, SUBB_RS_H
	MOV MUL2, #60
	CALL MUL16
	MOV SUBB1_L, MUL_RS_L
	MOV SUBB1_H, MUL_RS_H
	MOV SUBB2_L, #4EH
	MOV SUBB2_H, #1H
	CALL DIV16
	MOV ADD1_L, DIV_RS
	MOV ADD1_H, #0

	MOV A, COUNT
	MOV B, #60
	MUL AB
	MOV ADD2_L, A
	MOV ADD2_H, B
	CALL ADD16
	MOV RPM_L, ADD_RS_L
	MOV RPM_H, ADD_RS_H

	RET

SHOW:
	MOV A, #1H		; CLEAR LCD
	CALL LCD_WR_CMD

	MOV A, #"R"
	CALL LCD_WR_DATA
	MOV A, #'P'
	CALL LCD_WR_DATA
	MOV A, #'M'
	CALL LCD_WR_DATA
	MOV A, #':'
	CALL LCD_WR_DATA
	MOV A, #' '
	CALL LCD_WR_DATA

	MOV R5, RPM_L
	MOV R4, RPM_H
	; thousands
	MOV SUBB1_H, R4
	MOV SUBB1_L, R5
	MOV SUBB2_H, #3H	 ; 1000
	MOV SUBB2_L, #0E8H
	CALL DIV16			 ; Get thousands of RPM
	MOV A, DIV_RS
	ADD A, #48
	CALL LCD_WR_DATA

	; hundred
   	MOV SUBB1_H, R4
	MOV SUBB1_L, R5
	MOV SUBB2_H, #0H	 ; 100
	MOV SUBB2_L, #100
	CALL DIV16
	MOV A, DIV_RS
	MOV B, #10
	DIV AB
	MOV A, B
	ADD A, #48
	CALL LCD_WR_DATA

	; Dozens
	MOV A, DIV_RM
	MOV B, #10
	DIV AB
	ADD A, #48
	CALL LCD_WR_DATA

	; per
	MOV A, B
	ADD A, #48
	CALL LCD_WR_DATA
	
	RET

LCD_WR_CMD:
	MOV P2, A
	CLR RS
	CLR EN
	SETB EN
	MOV R7, #10 ; DELAY 
	CALL DELAY
	RET

LCD_WR_DATA:
	MOV P2, A
	SETB RS
	CLR EN
	SETB EN
	MOV R7, #1 ; DELAY 
	CALL DELAY
	RET

DELAY:
	; R7 - time	x 0.5 ms
DELAY_LOOP1:
	MOV R6, #250
DELAY_LOOP2:
	DJNZ R6, DELAY_LOOP2
	DJNZ R7, DELAY_LOOP1
	RET

;-----------------
SUBB16:
	; S1:  SUBB1_H SUBB1_L
	; S2:  SUBB2_H SUBB2_L
	; RS:  SUBB_RS_H SUBB_RS_L
	CLR C
	MOV A, SUBB1_L
	MOV B, SUBB2_L																											  
	SUBB A, B
	MOV SUBB_RS_L, A	; RS - 8LB
	
	MOV A, SUBB1_H
	MOV B, SUBB2_H
	SUBB A, B
	MOV SUBB_RS_H, A	; RS - 8HB
	RET

DIV16:
	MOV SUBB_RS_H, #0	;	RS - 8HB
	MOV SUBB_RS_L, #0	;	RS - 8LB
	MOV DIV_RS, #0		; 	
	MOV DIV_RM, #0		; 	
DIV16_LOOP:
	CALL SUBB16
	JC END_DIV16
	INC DIV_RS			; 
	
	MOV R1, SUBB_RS_H
	MOV R2, SUBB_RS_L
	
	MOV SUBB1_H, R1
	MOV SUBB1_L, R2	

	CJNE R1, #0, DIV16_LOOP
	MOV A, R2
	MOV B, SUBB2_L
	SUBB A, B
	JNC DIV16_LOOP
	MOV	DIV_RM, R2	
END_DIV16:
	RET

ADD16:
	MOV ADD_RS_H, #0
	MOV ADD_RS_L, #0

	; Cong 8 bit thap	
	MOV A, ADD1_L
	MOV B, ADD2_L
	ADD A, B
	MOV ADD_RS_L, A
	; Cong 8 bit cao va co nho	
	MOV A, ADD1_H
	MOV B, ADD2_H	
	ADDC A, B
	MOV ADD_RS_H, A

	RET

MUL16:
	MOV MUL_RS_H, #0
	MOV MUL_RS_L, #0

	MOV A, MUL1_L
	MOV B, MUL2
	MUL AB
	MOV ADD1_L, A
	MOV ADD1_H, B

	MOV A, MUL1_H
	MOV B, MUL2
	MUL AB
	MOV ADD2_L, #0
	MOV ADD2_H, A

	CALL ADD16

	MOV MUL_RS_H, ADD_RS_H
	MOV MUL_RS_L, ADD_RS_L
	
	RET

;-----------------
; Trinh phuc vu ngat timer 0
ISR_ET0:
	CLR TR0
	DJNZ COUNT_ET0, END_ISR_ET0
	MOV COUNT_ET0, #99
	MOV COUNT, TMP_COUNT
	MOV TMP_COUNT, #0
	MOV TMP_TH1, TH1
	MOV TMP_TL1, TL1
END_ISR_ET0:
	CLR TF0
	MOV TL0, #0F0H		; count 1s
	MOV TH0, #0D8H
	SETB TR0
	RETI

;-----------------
; Trinh phuc vu ngat timer 1
ISR_ET1:
	CLR TR1
	INC TMP_COUNT
	CLR TF1
END_ISR_ET1:
	CLR TF1
	MOV TL1, #0B2H		; Count 334 pulse
	MOV TH1, #0FEH
	SETB TR1
	RETI
END