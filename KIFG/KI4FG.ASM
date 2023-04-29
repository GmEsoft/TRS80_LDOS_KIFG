;=====	Model 4 $KI Driver  ===========================================
;
;	Relocation table for Model 4 driver
;
RELOKI4	DW	RX41,RX44,RX46,RX42
	DW	RX43,RX45
	IF	FREN+GERM	;--->
	DW	RX4A,RX4B,RX4C,RX4D
	DW	RX4E,RX4F
	ENDIF
	DW	0000H,0000H
;
;-----	Relocatable Driver Begin  -------------------------------------
;
;	Model 4 $KI driver
;
KIDVR4	JR	KISCAN4		;branch around linkage

KINXT4	DW	0000H		;last byte ptr (NEXT)
	DB	03H
	DB	'$KI'
;
;	Non-ECM conversion table
;
KBTBL4	DB	0DH,1DH,1FH,1FH,01H,00H,5BH,1BH	;Ent,Clr,Brk,Up
KBTBL4A	EQU	$-2
	DB	0AH,1AH,08H,18H,09H,19H,20H,20H ;Dwn,Lft,Rgt,Spc
	DB	81H,91H,82H,92H,83H,93H,00H,00H ;F1-F3
;
;	ECM conversion table
;
	DB	0DH,1DH,1FH,1FH,01H,00H,82H,92H ;Ent,Clr,Brk,Up
	DB	88H,98H,81H,91H,84H,94H,20H,20H ;Dwn,Lft,Rgt,Spc
	DB	81H,91H,82H,92H,83H,93H,00H,00H ;F1-F3
;
;	Table to generate 5B-5F, 7B-7F
;
SPCLTB4	DB	',','/','.',';',0DH
; No Shift:	'[','\',']','^','_'
; With Shift:	'{','|','}','~'

	IF	FREN+GERM	;--->
;
;	Extra key flag
;
EXDATA4	DB	0		;0,1,or 2 for spcl chars
	ENDIF			;<---
;
;	Driver to scan the keyboard
;
KBROW7$	DB	0FFH		;Image of KB7

KISCAN4	CALL	@KITSK		;Hook for KI task
KIOFFS4	EQU	$-KIDVR4	;Offset for type-ahead installer

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
L54A5	LD	A,(BC)		;Load 1st char from kbd
	LD	E,A
	XOR	(HL)		;XOR with old value
	JR	NZ,L54CE	;Go if different
	INC	D		;Bump key counter
	INC	L		;Bump image pointer
	RLC	C		;Go to next row
	JP	P,L54A5		;Loop until end of rows
RX41	EQU	$-2
	LD	A,(BC)		;scan row 7 (Sht,Ctl,Caps,F1-F3)
	AND	78H		;keep Caps and F1-F3
	LD	E,A
	LD	HL,KBROW7$	;Row 7 image
RX42	EQU	$-2
	XOR	(HL)		;XOR with old value
	JR	NZ,L54CE	;Go if different
	LD	A,(IX+3)	;Key down?  It's same as
	OR	A		;  the last if so
	RET	Z		;Ret if no key
	LD	A,(TIMER$)	;Do we repeat the
	SUB	(IX+4)		;  same key?
	JR	Z,L5531		;Go if yes
	SUB	0FH		;Beyond 0.75 seconds?
XRINI14	EQU	$-1
	JR	C,L5531		;Go if yes
	XOR	A		;Else don't repeat
	RET			;Show Z with A=0

;
;	Found change in key matrix
;
L54CE	LD	(HL),E		;Stuff KB image with new
	AND	E		;  KB row value
	JP	Z,NOKEY4	;Go if new is none
RX43	EQU	$-2
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
L54DB	LD	A,C
	AND	E		;Check if bits match
	JR	NZ,L54F8	;Go if match
	INC	D		;  else bump value
	RLC	C		;shift compare bit
	JR	L54DB		;Loop to test next
;
;	Key pressed was not an alpha
;
	IFEQ	FREN+GERM,0	;--->

L54E4	SUB	90H		;Adjust for non-alpha
	JR	NC,L5538	;Go if special key
	ADD	A,40H		;Cvrt to numeric/symbol
	CP	3CH		;Manipulate to get
	JR	C,L54F0		;  proper code
	XOR	10H
L54F0	BIT	0,E		;Check shift
	JR	Z,L5558		;Go if unshift
	XOR	10H		;  else adjust for shift
	JR	L5558

	ENDIF			;<---
;
;	Found a key - set up the function codes
;
L54F8	LD	A,(KB7)		;p/u the shift key
	LD	E,A		;Merge LH & RH shift keys
	AND	02H		;Bit 1 to bit 0
	RRCA			;Merge bits 0&1
	OR	E		;Value of RH or LH shift
	LD	E,A

	IF	FREN+GERM	;--->
;	DB	0EDH,0F5H
	LD	HL,KFLAG$3
	LD	A,D
	SUB	30H
	JR	NC,L5538
	LD	HL,TABLE4
RX4A	EQU	$-2
	LD	C,D
	LD	B,0
	ADD	HL,BC
	LD	A,E
	OR	A
	JR	Z,NOSHFT4
	LD	C,40H
	ADD	HL,BC
NOSHFT4	LD	A,(HL)
	LD	HL,KFLAG$3
	OR	A
	RET	Z
	LD	D,A
	OR	20H
	BIT	2,E		;Ctrl key down?
	JR	NZ,L552A	;
	LD	A,D
	SUB	0FAH
	JR	C,NDEADK4
	LD	D,0
	CP	02H
	JR	NC,DEADK4
	LD	D,A
	INC	D
DEADK4	LD	HL,EXDATA4
RX4B	EQU	$-2
	LD	(HL),D
	XOR	A
	RET
NDEADK4	LD	A,D
	CP	61H		;lower alpha?
	JR	C,L5558		;bypass if not
	CP	7BH		;
	JR	NC,L5558	;

	ELSE			;<-->

	LD	A,D		;Load semi-converted
	ADD	A,60H		;If alpha, convert to
	CP	80H		;  correct value
	LD	HL,KFLAG$3
	JR	NC,L54E4	;Go if not alpha
;
;	Alpha <@-Z> - If caps lock or <shift>,
;	Convert to caps unless CLEAR
;
	BIT	2,E		;Ctrl key down?
	JR	NZ,L552A	;CTRL sets <00-1A>
	CP	60H		;Invert @ and '
	JR	NZ,L5517
	XOR	20H		;Invert and bypass test
	JR	L5524		;  for caps lock

	ENDIF			;<---

L5517	LD	D,A
	LD	A,(403CH)	;KBROW$+6
	BIT	1,A		;If CLEAR, don't test
	LD	A,D
	JR	NZ,L5524	;  for caps lock
	BIT	5,(HL)		;Caps lock?
	JR	NZ,TGLCAS4
L5524	BIT	0,E		;Shift key down?
	JR	Z,L5558		;Bypass if not shifted
	JR	TGLCAS4		;Convert to upper case

L552A	SUB	60H		;Convert CTRL A-Z
	JR	NZ,L5558	;Go on A-Z
	CP	0FFH		;Set C flag for Ctrl-@
	RET			;and return

L5531	LD	A,(TIMER$)	;Advance time check
	ADD	A,01H		;  by 0.067 seconds
XRRATE4	EQU	$-1

	IF	FREN+GERM	;--->
	JP	L55B7		;Go output the key
RX4F	EQU	$-2
	ELSE			;<-->
	JR	L55B7		;Go output the key
	ENDIF			;<---
;
;	Special keys - rows 6 & 7
;
L5538	CP	0BH		;Compress F1-F3 keys
	JR	Z,CAPSKY4	;  while checking for CAP
	JR	C,L5540		;  F1-F3 to 8-10
	SUB	04H
L5540	ADD	A,A		;Index into table
	BIT	0,E		;  shifted code is + 1
	JR	Z,L5546
	INC	A
L5546	BIT	6,(HL)		;ECM mode?
	LD	HL,KBTBL4	;Pt to special char table
RX44	EQU	$-2
	JR	Z,L554F		;If yes,
	ADD	A,18H		;  shift to ECM mode table
L554F	LD	C,A		;Index the table
	LD	B,00H
	ADD	HL,BC
	LD	A,(HL)		;Load char from table
	JR	L5558		;Bypass restore of char

TGLCAS4	XOR	20H		;Toggle the case
L5558	CP	01H		;Break key?
	CALL	Z,4BEEH		;  call Break handler if yes
	LD	HL,403CH	;KBROW$+6
	BIT	1,(HL)		;CLEAR key pressed?
	JR	Z,NOTALF4	;Go if not down
	LD	D,A		;Save code
	RES	5,A		;Set to upper case for
	SUB	41H		;  test A-Z
	CP	1AH
	LD	A,D		;Get back actual char
	JR	NC,L5570	;Go if not A-Z
	XOR	20H		;Shift keyboard case
L5570	OR	80H		;Set bit 7 for CLEAR key
NOTALF4	BIT	0,E		;Shift key down?
	JR	Z,FIXCLR4	;Go if not
	CP	9FH		;Shift-Clear?
	JR	Z,FIXSCL4	;Go if so
	LD	L,3AH		;KBROW$+4 (0-7)
	CP	0A0H		;Shift-0 or Shift-Space?
	JR	NZ,L5588	;Go if not
	BIT	0,(HL)		;Ck zero key
	JR	NZ,KEYOK4	;go if so
	LD	A,40H		;Shift-Space = toggle ECM
	JR	CASHK$4

L5588	CP	20H		;Space?
	JR	NZ,KEYOK4	;go if not

	BIT	0,(HL)		;Ck zero key
	JR	Z,KEYOK4	;Go if not down
	LD	HL,KBTBL4A	;pointer to '[' in conv table
RX45	EQU	$-2
	LD	A,(HL)		;Shift-0 = toggle between '[' (5Ah)
	XOR	50H		;  and Up-Arrow (0Ah)
	LD	(HL),A
	JR	NOKEY4
;
;	Toggle the capslock bit in the KFLAG$
;
CAPSKY4	LD	A,20H		;CAPS wasn't 20H
CASHK$4	LD	HL,KFLAG$3	;Reverse case by
	XOR	(HL)		;  flipping bit 5
	LD	(HL),A
	JR	NOKEY4

FIXSCL4	XOR	80H		;Clear key?
FIXCLR4	CP	9FH		;Go if not
	JR	NZ,KEYOK4
NOKEY4	XOR	A
KEYOK4:
	IF	FREN+GERM	;--->
	CALL	DEADKY4		;Check for deadkey
RX4E	EQU	$-2
	ENDIF			;<---

	LD	(IX+3),A
	LD	BC,0280H	;Delay
	CALL	PAUSE@
	LD	A,(TIMER$)	;Set initialization
	ADD	A,0FH		;  repeat key delay
XRINI24	EQU	$-1
L55B7	LD	(IX+4),A	;Save new repeat time
	LD	A,(IX+3)	;Check if any key
	OR	A		;  code was saved
	RET	Z		;Ret if none
	BIT	2,E		;Shift key down?
	SCF			;Init carry
	JR	NZ,SPECL4	;Ret if CTRL
DVRXIT4	OR	A		;Check Bit 7 (Clr) and reset Cy
	RET	P		;Go if not CLEAR+key
SPECL4	PUSH	AF		;Save code
	LD	HL,SPCLTB4	;Special char table
RX46	EQU	$-2
	RES	7,A		;Turn off "CLEAR"
	LD	B,05H		;5 chars
	JR	NC,SPCLOK4	;  if not CTRL
	DEC	B		;  else only 4
SPCLOK4	LD	C,5BH		;starting char
SPCLLP4	CP	(HL)		;Is this it?
	JR	Z,HIT4		;Go if so
	XOR	10H		;Flip shift state
	CP	(HL)		;Is that it?
	JR	Z,HITWS4	;Go if so
	XOR	10H		;Flip back
	INC	HL		;Bump spcl table ptr
	INC	C		;Bump "convert to" char
	DJNZ	SPCLLP4		;Loop through table
	POP	AF		;Not found in table
	RET

HITWS4	SET	5,C		;Move to LC set
HIT4	POP	AF		;Restore orig char
	LD	A,C		;Load converted one
	JR	NC,DVRXIT4		;Go if ctrl key not down
	AND	1FH		;Force ctl code
	RET

	IF	FREN+GERM	;--->
;*=*=*
; look up special combinations
;*=*=*
DEADKY4	OR	A
	RET	Z
	LD	HL,EXDATA4
RX4C	EQU	$-2
	LD	C,(HL)
	LD	(HL),0
	LD	HL,EXTBL4
RX4D	EQU	$-2
	DEC	C
	INC	C
	RET	Z

ODDCHR4	LD	B,A		;Save input char
XLTLP14	LD	A,(HL)		;P/u possible match
	CP	B		;Does it match?
	JR	Z,MAT14		;Get it if so...
	INC	HL		;Bump past replacement chars
	INC	HL
	INC	HL		;To next match char
	OR	A		;Was this the end
	JR	NZ,XLTLP14	;No, keep going
	LD	A,B		;Restore char
	RET			;NC if no match
MAT14	LD	B,0		;
	ADD	HL,BC		;1 or 2
	LD	A,(HL)		;Get xlate char
	SCF			;Carry set if sub found
	RET
	ENDIF			;<---

	IF	FREN		;--->
;Table for French keyboard
;Lookup table for KB rows 1-7 (no shift) 64 chars
; zero is ignored - FAH to FFH are spcl functions
TABLE4	DB	'>qbcdefg'
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
EXTBL4
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
TABLE4	DB	'>abcdefg'
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
EXTBL4
; deadkey not used for German KB..
	DB	0		;End of table
	ENDIF			;<---

DVRLST4	EQU	$-1
;
;	Model 4 $KI driver length for relocation
;
KILEN4	EQU	DVRLST4-KIDVR4+1
;
;
	END
