;=====	Model III $KI Driver  =========================================
;
;	Relocation table for Model III driver
;
RELOKI3	DW	RX31,RX32,RX33
	IF	FREN+GERM	;--->
	DW	RX3A,RX3B,RX3C,RX3D
	DW	RX3E,RX3F,RX3G
	ENDIF			;<---
	DW	0000H,0000H
;
;-----	Relocatable Driver Begin  -------------------------------------
;
;	Model III $KI driver
;
KIDVR3	JR	KISCAN3		;branch around linkage

KINXT3	DW	0000H		;last byte ptr (NEXT)
	DB	03H
	DB	'$KI'
;
;	Non-ECM conversion table for keyboard row 7/8
;
KBTBL3	DB	0DH,1DH,1FH,1FH,01H,00H,5BH,1BH	;Ent,Clr,Brk,Up
	DB	0AH,1AH,08H,18H,09H,19H,20H,20H	;Dwn,Lft,Rgt,Spc
;
;	ECM conversion table for keyboard row 7/8
;
	DB	0DH,1DH,1FH,1FH,01H,00H,82H,92H	;Ent,Clr,Brk,Up
	DB	88H,1AH,81H,91H,84H,94H,20H,20H	;Dwn,Lft,Rgt,Spc
;
;	Table to generate 5B-5F, 7B-7F
;
SPCLTB3	DB	',','/','.',';',0DH
; No Shift:	'[','\',']','^','_'
; With Shift:	'{','|','}','~'

	IF	FREN+GERM	;--->
;
;	Extra key flag
;
EXDATA3	DB	0		;0,1,or 2 for spcl chars
	ENDIF			;<---
;
;	Driver to scan the keyboard
;
KIOFFS3	EQU	$-KIDVR3	;Offset for type-ahead installer
				;?? why @KITSK is skipped with
				;?? Model 4 driver but not with
				;?? Model III driver ?
KISCAN3	CALL	@KITSK		;Hook for KI task

	IF	FREN+GERM	;--->
	LD	HL,4210H
	RES	3,(HL)		;Disable alt char set
	LD	A,(HL)
	OUT	(0ECH),A
	LD	HL,4024H	;Disable space compression
	SET	7,(HL)
	ENDIF			;<---

	LD	HL,KBROW$	;Load kbd image start
	LD	BC,KB0		;Load start of keyboard
	LD	D,00H		;Zero the key counter
L5316	LD	A,(BC)		;Load 1st char from kbd
	LD	E,A
	XOR	(HL)		;XOR with old value
	JR	NZ,L5335	;Go if different
	INC	D		;Bump key counter
	INC	L		;Bump image pointer
	RLC	C		;Go to next row
	JP	P,L5316		;Loop until end of rows
RX31	EQU	$-2
	LD	A,(IX+3)	;Key down?  It's same as
	OR	A		;  the last if so
	RET	Z		;Ret if no key
	LD	A,(TIMER$)	;Do we repeat the
	SUB	(IX+4)		;  same key?

	IF	FREN+GERM	;--->
	JP	Z,L5398		;Go if yes
RX3F	EQU	$-2
	ELSE			;<-->
	JR	Z,L5398		;Go if yes
	ENDIF			;<---

	SUB	0FH		;Beyond 0.75 seconds?
XRINI13	EQU	$-1
	JR	C,L5398		;Go if yes
	XOR	A		;Else don't repeat
	RET			;Show Z with A=0
;
;	Found change in key matrix
;
L5335	LD	(HL),E		;Stuff KB image with new
	AND	E		;  KB row value
	IF	FREN+GERM	;--->
	JP	Z,L53B0		;Go if new is none
RX3G	EQU	$-2
	ELSE			;<-->
	JR	Z,L53B0		;Go if new is none
	ENDIF			;<---
;
;	Convert the depressed key
;
	LD	E,A		;Save the active bit
	LD	A,D		;Calculate 8*row
	RLCA
	RLCA
	RLCA
	LD	D,A		;Save 8*row
	LD	C,01H		;Add 8*row+column
L5341	LD	A,C
	AND	E		;Check if bits match
	JR	NZ,L535E	;Go if match
	INC	D		;  else bump value
	RLC	C		;shift compare bit
	JR	L5341		;Loop to test next
;
;	Key pressed was not an alpha
;
	IFEQ	FREN+GERM,0	;--->

L534A	SUB	70H		;Adjust for non-alpha
	JR	NC,L5382	;Go if special key
	ADD	A,40H		;Cvrt to numeric/symbol
	CP	3CH		;Manipulate to get
	JR	C,L5356		;  proper code
	XOR	10H
L5356	RRC	B		;Check shift
	JR	NC,L53A0	;Go if unshift
	XOR	10H		;  else adjust for shift
	JR	L53A0

	ENDIF			;<---
;
;	Found a key - set up the function codes
;
L535E	LD	A,(KB7)		;p/u the shift key
	LD	B,A		;Merge LH & RH shift keys
	RRCA			;Bit 1 to bit 0
	OR	B		;Merge bits 0&1
	LD	B,A		;Value of RH or LH shift

	IF	FREN+GERM	;--->

	;DB	0EDH,0F5H	;$BREAK
	;HALT
	JR	Z,NOSH31
	LD	A,(KB6)
	AND	10H		;Sh-Down (Ctrl on Mod III)
NOSH31	OR	B
	LD	E,A
	LD	HL,KFLAG$3
	LD	A,D
	SUB	30H
	JR	NC,L5382
	LD	HL,TABLE3
RX3A	EQU	$-2
	LD	C,D
	LD	B,0
	ADD	HL,BC
	LD	A,E
	OR	A
	JR	Z,NOSHFT3
	LD	C,40H
	ADD	HL,BC
NOSHFT3	LD	A,(HL)
	LD	HL,KFLAG$3
	OR	A
	RET	Z
	LD	D,A
	OR	20H
	BIT	4,E		;Ctrl key down?
	JR	NZ,L552A3	;
	LD	A,D
	SUB	0FAH
	JR	C,NDEADK3
	LD	D,0
	CP	02H
	JR	NC,DEADK3
	LD	D,A
	INC	D
DEADK3	LD	HL,EXDATA3
RX3B	EQU	$-2
	LD	(HL),D
	XOR	A
	RET
NDEADK3	;LD	A,D
	;CP	61H		;lower alpha?
	;JR	C,L53A0		;bypass if not
	;CP	7BH		;
	;JR	NC,L53A0	;
	;LD	B,E
	JR	L539F

	ELSE			;<-->

	LD	A,D		;Load semi-converted
	ADD	A,40H		;If alpha, convert to
	CP	60H		;  correct value
	JR	NC,L534A	;Go if not alpha
;
;	Alpha <@-Z> - If caps lock or <shift>,
;	Convert to caps unless CLEAR
;
	RRC	B		;Shift key down?
	JR	NC,L53A0	;Bypass if not shifted
	ADD	A,20H		;Convert to lower case
	LD	D,A
	LD	A,(KB6)		;Shift down-arrow?
	AND	10H		; (CTRL on Mod III)
	JR	Z,L539F		;go if not
	LD	A,D

	ENDIF			;<---

L552A3	SUB	60H		;a-z to ctrl_a-ctrl_z; Ctrl-@?
	JR	NZ,L53A0	;go if not
	CP	0FFH		;ret with C, NZ
	RET
;
;	Special keys - rows 6 & 7
;
L5382	RRC	B		;shift to Cy flag
	ADC	A,A		;  shifted code is + 1
	LD	HL,KFLAG$3	;Keyboard system flags
	BIT	6,(HL)		;ECM mode active ?
	LD	HL,KBTBL3	;Pt to special char table
RX32	EQU	$-2
	JR	Z,L5391
	ADD	A,10H		;bump to ECM mode table
L5391	LD	C,A		;Index the table
	LD	B,00H
	ADD	HL,BC
	LD	A,(HL)		;Load char from table
	JR	L53A0		;Bypass restore of char
;
;	Advance time check
;
L5398	LD	A,(TIMER$)	;Set initialization
	ADD	A,01H		;  repeat key delay
XRRATE3	EQU	$-1
	JR	L540E		;
;
;	Adjust key codes
;
L539F	LD	A,D		;depressed key
L53A0	CP	01H		;Break key?
	CALL	Z,4BEEH		;?? call BREAK handler if yes
	LD	BC,1A9FH	;B=Down (Ctrl-Z), C=Clear key code
	LD	HL,4039H	;KBROW$+3
	CP	B		;Ctrl-Z or Shift-Down?
	JR	NZ,L53B2	;if no, skip Z key checking
	BIT	2,(HL)		;Z key pressed?
L53B0	JR	Z,NOKEY3	;no key if not (Shift-Down)
L53B2	LD	L,3CH		;KBROW$+6
	BIT	1,(HL)		;CLEAR key?
	LD	HL,KB7		;SHIFT keys row
	JR	Z,L53BC		;skip if CLEAR not down
	OR	L		; else set bit 7 (L=80h) if
L53BC	LD	D,A		;save char
	RES	5,A		;LC to UC
	SUB	41H		;UC to CTLAZ-1
	CP	B		;test A-Z
	LD	A,D		;Get back actual char
	JR	NC,L53D2	;Go if not A-Z

	IFEQ	FREN+GERM,0	;--->
	XOR	20H		;Shift keyboard case
	ENDIF			;<---

	EX	DE,HL		;save SHIFT keys row ptr
	LD	HL,KFLAG$3	;kbd flags
	BIT	5,(HL)		;test CAPS
	EX	DE,HL		;restore SHIFT keys row ptr
	JR	Z,L53D2		;skip if CAPS off
	RES	5,A		;LC to UC
L53D2	BIT	0,(HL)		;test left SHIFT
	JR	NZ,L53DA	;skip if down
	BIT	1,(HL)		;test right SHIFT
	JR	Z,FIXCLR3	;go if not
L53DA	CP	C		;Shift-Clear?
	JR	Z,FIXSCL3	;Go if so
	LD	HL,403AH	;0-7 keys image
	CP	0A0H		;Shift-0 or Shift-Space?
	JR	NZ,TSTSPA3	;Go if not
	BIT	0,(HL)		;Ck zero key
	JR	NZ,KEYOK3	;Go if down
	LD	A,40H		;Shift-Space = toggle ECM mode
	JR	CASHK$3

TSTSPA3	CP	20H		;Space?
	JR	NZ,KEYOK3	;go if not
;
;	Toggle the capslock bit in the KFLAG$
;
	BIT	0,(HL)		;Ck zero key
	JR	Z,KEYOK3	;Go if not down
CASHK$3	LD	HL,KFLAG$3	;Kbd flags
	XOR	(HL)		;toggle CAPS(5) or ECM(6) flags
	LD	(HL),A		;save new flags
	JR	NOKEY3		;return with no key

FIXSCL3	XOR	L		;Reset bit 7
FIXCLR3	CP	C		;Clear key?
	JR	NZ,KEYOK3	;Go if not
NOKEY3	XOR	A
KEYOK3:
	IF	FREN+GERM	;--->
	CALL	DEADKY3		;Check for deadkey
RX3E	EQU	$-2
	ENDIF			;<---

	LD	(IX+3),A
	LD	BC,0280H	;Delay
	CALL	PAUSE@
	LD	A,(TIMER$)	;Set initialization
	ADD	A,0FH		;  repeat key delay
XRINI23	EQU	$-1
L540E	LD	(IX+4),A	;Save new repeat time
	LD	A,(IX+3)	;Check if any key
	OR	A		;  code was saved
	RET	Z		;Ret if none
	LD	HL,KB6		;Special keys row
	BIT	4,(HL)		;DOWN key down?
	JR	Z,DVRXIT3	;go if not
	LD	L,80H		;SHIFY keys row
	BIT	0,(HL)		;Left Shift key down?
	SCF			;Init carry
	JR	NZ,SPECL3	;Ret if not
DVRXIT3	OR	A		;reset Cy and test bit 7
	RET	P		;Go if not CLEAR+key
SPECL3	PUSH	AF		;Save code
	LD	HL,SPCLTB3	;Special char table
RX33	EQU	$-2
	RES	7,A		;Turn off "CLEAR"
	LD	B,05H		;5 chars
	JR	NC,SPCLOK3	;  if not Shift
	DEC	B		;  else only 4
SPCLOK3	LD	C,5BH		;starting char
SPCLLP3	CP	(HL)		;Is this it?
	JR	Z,HIT3		;Go if so
	XOR	10H		;Flip shift state
	CP	(HL)		;Is that it?
	JR	Z,HITWS3	;Go if so
	XOR	10H		;Flip back
	INC	HL		;Bump spcl table ptr
	INC	C		;Bump "convert to" char
	DJNZ	SPCLLP3		;Loop through table
	POP	AF		;Not found in table
	RET

HITWS3	SET	5,C		;Move to LC set
HIT3	POP	AF		;Restore orig char
	LD	A,C		;Load converted one
	JR	NC,DVRXIT3	;Go if ctrl key not down
	AND	1FH		;Force ctl code
	RET

	IF	FREN+GERM	;--->
;*=*=*
; look up special combinations
;*=*=*
DEADKY3	OR	A
	RET	Z
	LD	HL,EXDATA3
RX3C	EQU	$-2
	LD	C,(HL)
	LD	(HL),0
	LD	HL,EXTBL3
RX3D	EQU	$-2
	DEC	C
	INC	C
	RET	Z

ODDCHR3	LD	B,A		;Save input char
XLTLP13	LD	A,(HL)		;P/u possible match
	CP	B		;Does it match?
	JR	Z,MAT13		;Get it if so...
	INC	HL		;Bump past replacement chars
	INC	HL
	INC	HL		;To next match char
	OR	A		;Was this the end
	JR	NZ,XLTLP13	;No, keep going
	LD	A,B		;Restore char
	RET			;NC if no match
MAT13	LD	B,0		;
	ADD	HL,BC		;1 or 2
	LD	A,(HL)		;Get xlate char
	SCF			;Carry set if sub found
	RET
	ENDIF			;<---

	IF	FREN		;--->
;Table for French keyboard
;Lookup table for KB rows 1-7 (no shift) 64 chars
; zero is ignored - FAH to FFH are spcl functions
TABLE3	DB	'>qbcdefg'
	DB	'hijkl,no'
	DB	'parstuvz'
	DB	'xyw',0FBH,'@m',0DCH,7DH
	DB	0C1H,'&',0DBH,022H,027H,028H,0C9H,0DDH
	DB	'!',0C2H,')-$;:='
	DB	0DH,00H,01H,0BH,0AH,08H,09H,20H
	DB	00H,00H,00H,0FFH,81H,82H,83H,00H
; chars w/SHIFT - 64 chars
	DB	'<QBCDEFG'
	DB	'HIJKL?NO'
	DB	'PARSTUVZ'
	DB	'XYW',0FAH,'*M%',07BH
	DB	'01234567'
	DB	'89',0C6H,'_#./+'
	DB	1DH,1FH,01H,1BH,1AH,18H,19H,20H
	DB	00H,00H,00H,0FFH,91H,92H,93H,00H
; special chars table 1
;            char ! ctl-char ! clr-char
	DB	1FH,1FH,1FH	;CLEAR
	DB	0DH,0DH,'_'
	DB	1DH,1DH,127
	DB	',',27,91
	DB	'<',27,123
	DB	'.',29,93
	DB	'>',29,125
	DB	'/',28,92
	DB	'?',28,124
	DB	';',30,94
	DB	'+',30,126
	DB	':',0FDH,186	;Screen prnt
	DB	'@',00H,0FCH	;Null, clear type
	DB	'*',0FEH,'*'!80H	;EOF
	DB	0		;End of 1st table
;
EXTBL3
;               char, w/umlaut, w/circumflex
	DB	'a',0D6H,0E0H
	DB	'e',0E6H,0E1H
	DB	'i',0E7H,0E2H
	DB	'o',0D7H,0E3H
	DB	'u',0D8H,0E4H
	DB	' ',0DEH,0E5H
	DB	0		;End of table
	ENDIF			;<---

	IF	GERM		;--->
;Table for GERMAN keyboard (deadkey not used)
;Lookup table for KB rows 1-7 (no shift) 64 chars
; zero is ignored - FAH to FFH are spcl functions
TABLE3	DB	'>abcdefg'
	DB	'hijklmno'
	DB	'pqrstuvw'
	DB	'xzy',0D8H,'+',0D7H,0D6H,'#'
	DB	'01234567'
	DB	'89',0D9H,0C0H,'@,.-'
	DB	0DH,00H,01H,0BH,0AH,08H,09H,20H
	DB	00H,00H,00H,0FFH,81H,82H,83H,00H
; chars w/SHIFT - 64 chars
	DB	'<ABCDEFG'
	DB	'HIJKLMNO'
	DB	'PQRSTUVW'
	DB	'XZY',0D3H,'*',0D2H,0D1H,027H
	DB	'=!"',0C9H,'$%&/'
	DB	'()?',0C4H,60H,';:_'
	DB	1DH,1FH,01H,1BH,1AH,18H,19H,20H
	DB	00H,00H,00H,0FFH,91H,92H,93H,00H
; special chars table 1
;            char ! ctl-char ! clr-char
	DB	1FH,1FH,1FH	;CLEAR
	DB	0DH,0DH,'_'
	DB	1DH,1DH,127
	DB	',',27,91
	DB	'<',27,123
	DB	'.',29,93
	DB	'>',29,125
	DB	'/',28,92
	DB	'?',28,124
	DB	';',30,94
	DB	'+',30,126
	DB	':',0FDH,186	;Screen prnt
	DB	'@',60H,0FCH	; clear type
	DB	'*',0FEH,'*'!80H	;EOF
	DB	0		;End of 1st table
;
EXTBL3
; deadkey not used for German KB..
	DB	0		;End of table
	ENDIF			;<---

DVRLST3	EQU	$-1
;
;	Model III $KI driver length for relocation
;
KILEN3	EQU	DVRLST3-KIDVR3+1
;
;
	END

