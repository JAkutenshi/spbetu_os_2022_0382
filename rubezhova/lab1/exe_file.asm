SStack SEGMENT STACK
	DW 128 DUP(?)
SStack ENDS
; ****************************************
DATA SEGMENT

OTHER_TYPE DB 'IBM PC TYPE:     ', 0DH, 0AH, '$'
PC DB 'IBM PC TYPE: PC', 0DH, 0AH, '$'
XT DB 'IBM PC TYPE: PC/XT', 0DH, 0AH, '$'
PC_AT DB 'IBM PC TYPE: AT', 0DH, 0AH, '$'
PS2_30 DB 'IBM PC TYPE: PS2 model 30', 0DH, 0AH, '$'
PS2_5060 DB 'IBM PC TYPE: PS2 model 50 or 60', 0DH, 0AH, '$'
PS2_80 DB 'IBM PC TYPE: PS2 model 80', 0DH, 0AH, '$'
PCjr DB 'IBM PC TYPE: PCjr', 0DH, 0AH, '$'
PC_CNVRT DB 'IBM PC TYPE: PC Convertible', 0DH, 0AH, '$'

DOS_VERSION DB 'MS DOS Version:  .  ', 0DH, 0AH, '$'
OEM DB 'OEM number:   ', 0DH, 0AH, '$'
USER DB 'User number:       h', 0DH, 0AH, '$'

DATA ENDS
; ****************************************
TESTPC SEGMENT
	
	ASSUME CS:TESTPC, DS:DATA, SS:SStack

; procedures
TETR_TO_HEX PROC near
		and AL, 0Fh
		cmp AL, 09
		jbe NEXT
		add AL, 07
NEXT:	add AL, 30h
		ret
TETR_TO_HEX ENDP
; -------------------------------------------------------
; байт в AL переводится в два символа шестн. числа в AX
BYTE_TO_HEX	PROC near
		push CX
		mov AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov CL, 4
		shr AL, CL
		call TETR_TO_HEX
		pop CX
		ret
BYTE_TO_HEX ENDP
; -------------------------------------------------------
; перевод в 16 с/с 16-ти разрядного числа в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
		push BX
		mov BH, AH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		dec DI
		mov AL, BH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		pop BX
		ret
WRD_TO_HEX ENDP
; -------------------------------------------------------
; перевод в 10 с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
		push CX
		push DX
		xor AH, AH
		xor DX, DX
		mov CX, 10
loop_bd:	div CX
		or DL, 30h
		mov [SI], DL
		dec SI
		xor DX, DX
		cmp AX, 10
		jae loop_bd
		cmp AL, 00h
		je end_l
		or AL, 30h
		mov [SI], AL
end_l:	pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP
; -------------------------------------------------------
; Основной код
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP

PC_TYPE PROC near
	push AX
	push ES
	push DX
	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh] ; get a byte about pc_type
	
	;compare and match with the data of table
	cmp AL, 0FFh
	je _PC
	
	cmp AL, 0FEh
	je _XT
	
	cmp AL, 0FBh
	je _XT
	
	cmp AL, 0FCh
	je _AT
	
	cmp AL, 0FAh
	je _ps2_30
	
	cmp AL, 0FCh
	je _ps2_5060
	
	cmp AL, 0F8h
	je _ps2_80
	
	cmp AL, 0FDh
	je _pcjr
	
	cmp AL, 0F9h
	je _pc_conv	
	
	mov DI, offset OTHER_TYPE + 13 ; to correct the result string about other type
	call BYTE_TO_HEX 
	mov [DI], AX ; add hex-number to the result string
	mov DX, offset OTHER_TYPE
	jmp label1
	
_PC:
	mov DX, offset PC
	jmp label1
_XT:
	mov DX, offset XT
	jmp label1
_AT:
	mov DX, offset PC_AT
	jmp label1
_ps2_30:
	mov DX, offset PS2_30
	jmp label1
_ps2_5060:
	mov DX, offset PS2_5060
	jmp label1
_ps2_80:
	mov DX, offset PS2_80
	jmp label1
_pcjr:
	mov DX, offset PCjr
	jmp label1
_pc_conv:
	mov DX, offset PC_CNVRT
	jmp label1
label1:
	call PRINT
	pop DX
	pop ES
	pop AX
	ret
PC_TYPE ENDP
; ----------------------------------------------------
DOS_VER PROC near
	push AX
	push BX
	push CX

	sub AX, AX
	mov AH, 30h
	int 21h

	mov SI, offset DOS_VERSION + 16
	call BYTE_TO_DEC
	mov AL, AH ; AH-DOS VER
	add SI, 3
	call BYTE_TO_DEC
	mov DX, offset DOS_VERSION
	call PRINT

	mov SI, offset OEM + 13
	mov AL, BH 	; BH - OEM NUMBER
	call BYTE_TO_DEC
	mov DX, offset OEM
	call PRINT

	mov DI, offset USER + 18
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	mov DI, offset USER + 13
	mov [DI], AX
	mov DX, offset USER
	call PRINT

	pop CX
	pop BX
	pop AX
	ret
DOS_VER ENDP
; ****************************************
MAIN PROC far
	call PC_TYPE
	call DOS_VER
; Выход в DOS
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP
; ****************************************
TESTPC ENDS
	END MAIN
