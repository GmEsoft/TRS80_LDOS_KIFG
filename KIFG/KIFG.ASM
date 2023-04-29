;==============================================================================
;
;	KI/DVR International version for LDOS 5.3 - Version 0.3
;
;	Original QWERTY version (c) 1991 MISOSYS, Inc.
;	International version (c) 2023 GmEsoft.
;
;	Build using George Phillips' ZMAC (http://www.48k.ca/zmac.html):
;	ZMAC KIFG.ASM [-P1=1|-P2=1] -o KIFG.CMD -o KIFG.LST -o KIFG.BDS -c -g --mras
;	with:
;		-P1=1 for the AZERTY French version
;		-P2=1 for the QWERTY German version
;	Then rename KIFG.CMD to KIFR.DVR or KIGR.DVR .
;
;	To load in LDOS 5.3:
;	SET *KI KIFR
;	or
;	SET *KI KIGR
;
;==============================================================================

	IF	@@1
FREN	EQU	@@1		;-P1=1: build the FR version
	ELSE
FREN	EQU	0
	ENDIF

	IF	@@2
GERM	EQU	@@2		;-P2=1: build the FR version
	ELSE
GERM	EQU	0
	ENDIF

	IF	@@3
FORCE3	EQU	@@3		; -P3=1: test Mod III dvr on Mod 4
	ELSE
FORCE3	EQU	0
	ENDIF

	IF	FREN+GERM
	IF	FREN
	NAME	'KIFR  '
	ELSE
	NAME	'KIGR  '
	ENDIF
	ELSE
	NAME	'KI    '
	ENDIF

PRT@	EQU	003BH
PAUSE@	EQU	0060H
KB0	EQU	3801H
KB6	EQU	3840H
KB7	EQU	3880H
KIPTR$	EQU	4016H
@EXIT	EQU	402DH
@ABORT	EQU	4030H
KBROW$	EQU	4036H
@ADTSK	EQU	403DH
OFLAG$4	EQU	40ADH
@KITSK	EQU	4285H
TIMER$	EQU	4288H
DFLAG$3	EQU	4289H
@LOGOT3	EQU	428AH
KFLAG$3	EQU	429FH
KIJCL$	EQU	42BEH
@ERROR	EQU	4409H
HIGH$3	EQU	4411H
SFLAG$3	EQU	442BH
@PARAM	EQU	4454H
@DSPLY1	EQU	4467H
CFLAG$1	EQU	4758H
TYEND$	EQU	4DF2H
JKEND$	EQU	4DF4H
KIDVR$	EQU	4DF8H


	IF	FREN+GERM
	ORG	5C00H		;SET loader resides between 5A00H and 5BFFH ...
	ELSE
	ORG	5200H
	ENDIF

;=====	Driver installer entry point  =================================
KISTART
	NOP
	;DB	0EDH,0F5H	;$BREAK
	PUSH	DE		;driver loader entry point
	PUSH	HL
	LD	HL,TITLE$	;greet the people
	CALL	@DSPLY1
	LD	A,(CFLAG$1)	;test if invoked via SET
	BIT	3,A
	JP	Z,ENOSET	;abort if not
	POP	HL		;params
	POP	IX		;*KI DCB
	LD	DE,PARAM$
	CALL	@PARAM		;parse params
	JP	NZ,EPARAM	;abort on error
	LD	C,84H		;Model 4 memory mapper I/O port
	LD	A,(OFLAG$4)	;port 84H image
	LD	B,A
	LD	HL,3C00H	;start video RAM Model III mode
	LD	A,H
	LD	(HL),A		;write a char in video RAM page 0
	CPL			;complement character's bits
	LD	E,A		;
	SET	7,B		;video RAM page select bit
	OUT	(C),B		;select video RAM page 1
	LD	(HL),A		;write character's complement
	RES	7,B		;
	OUT	(C),B		;reselect video RAP page 0
	LD	A,(HL)		;read written char
	LD	(HL),20H	;write white space
	IF	FORCE3		;--->
	XOR	A		;force Mod III
	ELSE			;<-->
	XOR	E		;compare with char's complement
	ENDIF			;<---
	LD	(XMODEL4),A	;00h for Mod III - 0FFh for Mod 4
	LD	BC,000FH	;Repeat delay from parameter D/DELAY
XPDELAY	EQU	$-2		;default is 15
	LD	A,0AH		;minimum is 10
	CP	C
	JR	NC,DELAYOK	;use 10 if param < 10
	LD	A,C
DELAYOK	LD	(XRINI13),A	;write delay in driver relocatable code
	LD	(XRINI23),A
	LD	(XRINI14),A
	LD	(XRINI24),A
	LD	BC,0001H	;repeat rate from parameter R/RATE
XPRATE	EQU	$-2		;default is 1
	LD	A,01H		;minimum is 1
	CP	C		;
	JR	NC,RATEOK	;use 1 if < 1
	LD	A,C		;
RATEOK	LD	(XRRATE3),A	;write rate in driver relocatable code
	LD	(XRRATE4),A
	LD	(XRRATT1),A
	LD	(XRRATT2),A
	LD	A,00H		;Model 4 flag
XMODEL4	EQU	$-1
	OR	A		;
	LD	BC,KILEN4	;Model 4 relocatable dvr length
	JR	NZ,MOD4OK1	;use it if Model 4 flag is set
	LD	BC,KILEN3	;Model III relocatable dvr length
MOD4OK1	LD	HL,(KIDVR$)	;*KI dvr pointer in DOS memory area
	PUSH	HL
	INC	HL
	INC	HL
	LD	E,(HL)		;load old HIGH$ value before initial
	INC	HL		;  load of the driver (in case of reload)
	LD	D,(HL)
	POP	HL
	LD	A,H		;test if driver was already installed
	OR	L
	JR	NZ,KIPRES	;jump if yes
	LD	HL,(HIGH$3)	;current HIGH$
	LD	E,L		;will be used as next module ptr
	LD	D,H		;  in high memory
	XOR	A
	SBC	HL,BC		;less the driver length
	LD	(HIGH$3),HL	;new HIGH$
	INC	HL
	LD	(KIDVR$),HL	;save driver entry point in DOS memory
KIPRES	LD	(KINXT4),DE	;save next module ptr in driver relocatable
	LD	(KINXT3),DE	;  code
	PUSH	BC		;driver length
	PUSH	DE		;NEXT ptr
	LD	IY,RELOKI4	;relocation table for Model 4 driver
	LD	HL,DVRLST4	;Model 4 driver end pointer
	LD	A,(XMODEL4)	;test if Model 4
	OR	A
	JR	NZ,MOD4OK2	;jump if yes
	LD	IY,RELOKI3	;relocation table for Model III driver
	LD	HL,DVRLST3	;Model III driver end pointer
MOD4OK2	CALL	RELO		;relocate absolute addresses in driver
	POP	DE		;NEXT ptr
	POP	BC		;driver length
	LD	HL,DFLAG$3	;DOS features flags address
	BIT	4,(HL)		;test if KI/DVR is active
	JP	NZ,EKIACT	;abort if yes
	SET	4,(HL)		;set KI/DVR active flag
	LD	HL,DVRLST4	;Model 4 driver end pointer
	LD	A,(XMODEL4)	;test if Model 4
	OR	A
	JR	NZ,MOD4OK3	;jump if yes
	LD	HL,DVRLST3	;Model III driver end pointer
MOD4OK3	LDDR			;move driver to high memory
	DI
	LD	(IX+0),01H	;init *KI DCB
	INC	DE		;driver entry point
	EX	DE,HL
	CALL	SETVEC		;set vector to *KI or KIJCL
	EI
	JP	INSTTYP		;proceed with type-ahead installation
;
;
;=====	Model III $KI Driver  =========================================
;
*GET	KI3FG			;Model III *KI dvr
;
;=====	Model 4 $KI Driver  ===========================================
;
*GET	KI4FG			;Model 4 *KI dvr
;
;=====	Type-Ahead Driver  ============================================
;
;	Install Type-Ahead driver
;
INSTTYP	LD	BC,0000H
XPTYPE	EQU	$-2
	LD	A,B
	OR	C
	JP	Z,INSTJKL
	LD	HL,DFLAG$3
	BIT	1,(HL)
	JP	NZ,ETYACT
	SET	1,(HL)
	LD	HL,(TYEND$)
	LD	A,H
	OR	L
	PUSH	AF
	JR	NZ,L560C
	LD	HL,(HIGH$3)
	LD	(TYEND$),HL
L560C	LD	(TYNXT),HL
	DEC	H
	LD	(HL),00H
	DEC	HL
	LD	(HL),00H
	DEC	HL
	LD	(HL),00H
	LD	(RXTY1),HL
	LD	(RXTY3),HL
	EX	DE,HL
	LD	HL,(KIPTR$)
	LD	A,(SFLAG$3)
	BIT	5,A
	JR	Z,L562C
	LD	HL,(KIJCL$)
L562C	LD	BC,KIOFFS4	;Model 4 $KI start offset
	LD	A,(XMODEL4)
	OR	A
	JR	NZ,L5638
	LD	BC,KIOFFS3	;Model III $KI start offset
L5638	ADD	HL,BC
	LD	(RXTY4),HL
	LD	(RXTY2),HL
	EX	DE,HL
	LD	BC,TYLEN
	DEC	HL
	XOR	A
	SBC	HL,BC
	POP	AF
	JR	NZ,L564D
	LD	(HIGH$3),HL
L564D	INC	HL
	PUSH	HL
	EX	DE,HL
	LD	HL,TYDVR
	LDIR
	DI
	LD	(IX+0),05H
	POP	HL
	PUSH	HL
	CALL	SETVEC
	EI
	POP	HL
	LD	DE,0048H
	ADD	HL,DE
	LD	D,H
	LD	E,L
	INC	DE
	INC	DE
	LD	(HL),E
	INC	HL
	LD	(HL),D
	DEC	HL
	EX	DE,HL
	LD	A,0AH
	CALL	@ADTSK
	JP	INSTJKL

SETVEC	LD	A,(SFLAG$3)
	BIT	5,A
	JR	NZ,L5684
	LD	(IX+1),L
	LD	(IX+2),H
	RET

L5684	LD	(KIJCL$),HL
	RET
;
;-----	Relocatable Driver Begin  -------------------------------------
;
;	Type-Ahead Driver
;
TYDVR	JR	TYBGN		;Branch around linkage

TYNXT	DW	0000H		;Last byte used
	DB	03H
	DB	'$TA'
;
;	Check the type ahead buffer for any character
;
TYBGN	PUSH	AF		;Save flags
	CALL	@KITSK		;Hook for KI task
	POP	AF
	LD	HL,0000H	;p/u start of type buffer
RXTY1	EQU	$-2
	LD	(HL),0FFH	;Turn off type ahead
	JR	C,TYGET		;Go on @GET
	JR	Z,TYGET		;No PUT to *KI
	LD	A,C		;request to clear buffer?
	OR	A
	JR	Z,CLRTYP	;Clear buffer if so
;
TYGET	PUSH	HL
	INC	HL		;Bump to PUT pointer
	LD	A,(HL)		;  & pick it up
	INC	HL		;Bump to GET pointer
	CP	(HL)		;The same?
	JR	Z,TYGKBD		;Go if so
	PUSH	HL		;Save pointer to GETPTR
	LD	E,(HL)		;p/u offset to buffer
	INC	HL		;Pt to buffer start
	LD	D,00H		;Add offset to start
	ADD	HL,DE		;  to point to char posn
	LD	B,(HL)		;GET the stored char
	INC	HL
	LD	C,(HL)		;get the flags
	POP	HL		;Recover GETPTR
	INC	(HL)		;Bump by 1 for char
	INC	(HL)		;Bump by 1 for flags
	LD	A,(HL)		;If we emptied the
	DEC	HL		;  type ahead buffer
	CP	(HL)		;  update KFLAG$
	JR	NZ,NOR7K$
	LD	HL,KFLAG$3	;Reset bit 7 if empty
	RES	7,(HL)
NOR7K$	POP	HL		;Pointed to & get switch
	LD	(HL),00H	;Turn type back on
	PUSH	BC		;Transfer char/flags
	POP	AF
	RET
;
;	No character in type ahead buffer - get from kbd
;
TYGKBD	LD	IX,4015H	;*KI dcb
	CALL	0000H		;Call keyboard driver
RXTY2	EQU	$-2
	POP	HL		;Recover switch
	LD	(HL),00H	;Set type ahead back on
	RET
;
;	Type ahead task 10 - scans keyboard and saves key
;
	DW	L56D2		;Task entry for processor

L56D2	LD	A,(DFLAG$3)	;If type-ahead suppressed
	AND	02H		;  then return
	RET	Z
	LD	HL,0000H	;p/u type switch
RXTY3	EQU	$-2
	LD	A,(HL)		;if previous driver is
	OR	A		;  currently executing,
	RET	NZ		; do not stack more keys
	INC	HL		;Bump to PUTPTR
	PUSH	HL		;  and save it
	LD	IX,4015H	;*KI dcb
	CALL	0000H		;  and scan for a character
RXTY4	EQU	$-2
	POP	HL
	INC	A
	DEC	A
	RET	Z		;Return if no char
	PUSH	AF		;  else xfer char
	POP	BC		;  and flag to BC
	CP	0C0H		;If CLEAR-@, reset keybuf
	JR	Z,CLRTYP1
	LD	E,(HL)		;p/u PUTPTR & compare
	LD	A,E		;  GETPTR
	INC	HL
	CP	(HL)
	JR	Z,TYSTUFF	;Jump if key buffer empty
	LD	A,(TIMER$)	;Check if we expired the
	ADD	A,01H		;  time interval between
XRRATT1	EQU	$-1
	CP	(IX+4)		;  repeating keys
	JR	NZ,TYCHECK	;Go if time not up
	ADD	A,01H		;Re-adjust time check so
XRRATT2	EQU	$-1
	LD	(IX+4),A	;  we don't repeat in
	RET
;
;	CLEAR-@ control key entered - Clear the buffer
;
CLRTYP	INC	HL		;Bump to PUT pointer
CLRTYP1	LD	(HL),02H
	INC	HL
	LD	(HL),00H
	INC	HL
	LD	(HL),00H
	INC	HL
	LD	(HL),40H
	LD	HL,KFLAG$3	;Show buffer empty
	RES	7,(HL)
	RET
;
;	Char to stuff - check if buffer will overflow
;
TYCHECK	LD	A,E		;p/u current PUT pointer
	INC	A		;if the next loc'n wraps
	INC	A
	CP	(HL)		;  to the GET loc'n,
	RET	Z		;  don't permit overrun
TYSTUFF	PUSH	HL		;Sve ptr to GETPTR
	INC	HL		;Point to start of keybuf
	LD	D,00H		;  & calculate PUT loc'n
	ADD	HL,DE
	LD	(HL),B		;Store the char
	INC	HL		;Bump ptr
	LD	(HL),C		;Store the flags
	LD	HL,KFLAG$3	;Show type buffer
	SET	7,(HL)		;  is not empty
	POP	HL		;Recover ptr to GETPTR
	DEC	HL		;backup to PUTPTR
	INC	(HL)		;Bump past the char
	INC	(HL)		;Bump past the flags
TYLST	RET
;
;	$TA driver length for relocation
;
TYLEN	EQU	TYLST-TYDVR+1
;
;
;=====	JKL Print Screen Driver  ======================================
;
;
;	Install JKL print screen driver
;
INSTJKL	LD	BC,0000H
XPJKL	EQU	$-2
	LD	A,B
	OR	C
	JP	Z,L5785
	LD	HL,DFLAG$3
	BIT	2,(HL)
	JP	NZ,EJKACT
	SET	2,(HL)
	LD	DE,(KIPTR$)
	LD	A,(SFLAG$3)
	BIT	5,A
	JR	Z,L5751
	LD	DE,(KIJCL$)
L5751	LD	(RX00),DE
	LD	BC,JKLLEN
	LD	HL,(JKEND$)
	LD	A,H
	OR	L
	PUSH	AF
	JR	NZ,L5766
	LD	HL,(HIGH$3)
	LD	(JKEND$),HL
L5766	LD	(JKLNXT),HL
	XOR	A
	SBC	HL,BC
	POP	AF
	JR	NZ,L5772
	LD	(HIGH$3),HL
L5772	INC	HL
	PUSH	HL
	EX	DE,HL
	LD	HL,0046H
	ADD	HL,DE
	LD	(RX01),HL
	LD	HL,JKLDVR
	LDIR
	POP	HL
	CALL	SETVEC
L5785:
	IF	0		;FREN+GERM
	LD	HL,4210H
	RES	3,(HL)		;Disable alt char set
	LD	A,(HL)
	OUT	(0ECH),A
	LD	HL,4024H
	SET	7,(HL)
	ENDIF
	JP	@EXIT
;
;-----	Relocatable Driver Begin  -------------------------------------
;
;	JKL Print Screen Driver
;
JKLDVR	JR	JKLBGN		;Branch around linkage

JKLNXT	DW	0000H		;Last byte used
	DB	04H
	DB	'$JKL'
;
;	Screen print (Control-*) processing
;
JKLBGN	CALL	0000H		;Chain downstream
RX00	EQU	$-2
	RET	NC		;Return if not <CONTROL>
	PUSH	AF		;Save flag state
	CP	2AH
	JR	Z,DOJKL		;Go if screen print
	POP	AF
	RET
;
;	Perform a screen print
;
DOJKL	POP	AF		;Check on graphic init
	PUSH	BC
	PUSH	DE
	LD	A,(DFLAG$3)	;Check on graphic init
	RLCA
	LD	A,3EH		;Init for LD A,'.'
	JR	NC,L57A9	;Go if not graphic
	LD	A,0FEH		;Change to CP N
L57A9	LD	(JKDOT),A	;Stuff CP or LD instr
RX01	EQU	$-2
	LD	HL,3C00H	;Video RAM origin
JKLINE	LD	A,(KB6)		;Check for Break key
	AND	04H
	JR	NZ,JKLEND	;Terminate if Break down
	LD	A,L		;check for new vid line
	AND	3FH
	LD	A,0DH		;New Line
	CALL	Z,PRT@		;output to printer if yes
	BIT	6,H		;check for end of video RAM
	JR	NZ,JKEXIT	;exit loop if yes
	LD	A,(HL)		;get character from vid RAM
	INC	HL		;bump ptr
	CP	20H
	JR	NC,JKCHROK	;Convert control codes
	ADD	A,40H		;  to cap A-Z and
JKCHROK	CP	80H		;Convert anything from 80h
	JR	C,L57D0		;  through FFh to '.'
JKDOT	LD	A,2EH		;  unless graphic bit set
L57D0	CALL	PRT@		;Print the character & loop
	JR	JKLINE		;Loop

JKLEND	LD	A,0DH		;Close out with CR if
	CALL	PRT@		;  BREAK key detected
JKEXIT	POP	DE		;restore regs and exit
	POP	BC
	XOR	A
JKLLST	RET
;
;	$JKL driver length for relocation
;
JKLLEN	EQU	JKLLST-JKLDVR+1
;
;
;=====	Installation helper routines  =================================
;
;
;	Relocate absolute addresses in driver
;
;	IY = relocation table
;	HL = origin
;	DE = destination
RELO	EX	DE,HL		;swap origin and dest
	OR	A
	SBC	HL,DE		;calculate offset
	LD	B,H		;offset to BC
	LD	C,L
RELOLP	LD	L,(IY+0)	;get entry from table
	LD	H,(IY+1)	;in HL
	LD	A,L		;end of table?
	OR	H
	RET	Z		;return if yes
	LD	E,(HL)		;read absolute address
	INC	HL		;to DE
	LD	D,(HL)
	EX	DE,HL		;swap ptr and value
	ADD	HL,BC		;offset value
	EX	DE,HL		;swap back ptr and value
	LD	(HL),D		;put back adjusted address
	DEC	HL
	LD	(HL),E
	INC	IY		;bump table ptr to next entry
	INC	IY
	JR	NZ,RELOLP	;loop
				;??why not unconditional JR??
;
;	Abort with messages
;
ENOSET	LD	HL,ENOSET$	;Must be installed via SET
	LD	IX,EJKACT$	;JKL already active
EJKACT	EQU	$-3
	LD	IX,EKIACT$	;KI/DVR already active
EKIACT	EQU	$-3
	LD	IX,ETYACT$	;Type-ahead already active
ETYACT	EQU	$-3
	CALL	@LOGOT3
	JP	@ABORT

EPARAM	LD	A,6CH		;Bad Parameter(s)
	CALL	@ERROR
;
;
;=====	Messages and data  ============================================
;
;
;
;	Messages
;
TITLE$	DB	'KI - LDOS Keyboard Input Driver - Version 5.3.1 ',0AH
	IF	FREN
	DB	'French'
	ENDIF
	IF	GERM
	DB	'German'
	ENDIF
	IF	FREN+GERM
	DB	' keyboard support by GmEsoft - Version 0.3',0AH
	ENDIF
	DB	'Copyright 1991 MISOSYS, Inc., All rights reserved',0AH,0DH
ENOSET$	DB	'Must be installed via: SET!',0DH
EKIACT$	DB	'KI/dvr is already active!',0DH
ETYACT$	DB	'Type-ahead is already active!',0DH
EJKACT$	DB	'JKL is already active!',0DH
;
;	Parameters table
;
PARAM$	DB	'TYPE  '
	DW	XPTYPE
	DB	'T     '
	DW	XPTYPE
	DB	'JKL   '
	DW	XPJKL
	DB	'J     '
	DW	XPJKL
	DB	'RATE  '
	DW	XPRATE
	DB	'R     '
	DW	XPRATE
	DB	'DELAY '
	DW	XPDELAY
	DB	'D     '
	DW	XPDELAY
	DB	00H


;
;
;=====	End  ==========================================================
;
;
	END	KISTART

