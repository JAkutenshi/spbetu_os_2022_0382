TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START:	JMP  BEGIN

PC db 'PC TYPE: PC', 0DH, 0AH, '$'
PC_XT db 'PC TYPE: PC/XT', 0DH, 0AH, '$'
AT db 'PC TYPE: AT', 0DH, 0AH, '$'
PS2_MODEL_30 db 'PC TYPE: PS2 model 30', 0DH, 0AH, '$'
PS2_MODEL_50_OR_60 db 'PC TYPE: PS2 model 50 or 60', 0DH, 0AH, '$'
PS2_MODEL_80 db 'PC TYPE: PS2 model 80', 0DH, 0AH, '$'
PCjr db 'PC TYPE: PCjr', 0DH, 0AH, '$'
PC_CONVERTIBLE db 'PC TYPE: PC Convertible', 0DH, 0AH, '$'
DOS_VERSION db 'MS DOS Version:  .  ', 0DH, 0AH, '$'
OEM_NUMBER db 'OEM number:    ', 0DH, 0AH, '$'
USER_NUMBER db 'User number:    ', 0DH, 0AH, '$'

TETR_TO_HEX PROC near
		and AL, 0Fh
		cmp AL, 09
		jbe NEXT
		add AL, 07
NEXT:	add AL, 30h
		ret
TETR_TO_HEX ENDP

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

PRINT_PC_TYPE PROC NEAR
	push AX
	push ES
	push DX

	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh]

	cmp AL, 0FFh
	je pc_type

	cmp AL, 0FEh
	je pc_xt_type

	cmp AL, 0FBh
	je pc_xt_type

	cmp AL, 0FCh
	je at_type

	cmp AL, 0FAh
	je ps2_model_30_type

	cmp AL, 0FCh
	je ps2_model_50_or_60_type

	cmp AL, 0F8h
	je ps2_model_80_type

	cmp AL, 0FDh
	je pcjr_type

	cmp AL, 0F9h
	je pc_convertible_type

pc_type:
	mov DX, offset PC
	jmp PRINT_MESSAGE

pc_xt_type:
	mov DX, offset PC_XT
	jmp PRINT_MESSAGE

at_type:
	mov DX, offset AT
	jmp PRINT_MESSAGE

ps2_model_30_type:
	mov DX, offset PS2_MODEL_30
	jmp PRINT_MESSAGE

ps2_model_50_or_60_type:
	mov DX, offset PS2_MODEL_50_OR_60
	jmp PRINT_MESSAGE

ps2_model_80_type:
	mov DX, offset PS2_MODEL_80
	jmp PRINT_MESSAGE

pcjr_type:
	mov DX, offset PCjr
	jmp PRINT_MESSAGE

pc_convertible_type:
	mov DX, offset PC_CONVERTIBLE
	jmp PRINT_MESSAGE

PRINT_MESSAGE:
	mov AH, 09h
	int 21h

	pop DX
	pop ES
	pop AX

	ret
PRINT_PC_TYPE ENDP

PRINT_MES_SYS PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT_MES_SYS ENDP

PRINT_SYSTEM_VERSION PROC near
	push AX
	push BX
	push CX
	push DI
	push SI

	sub AX, AX
	mov AH, 30h
	int 21h

	mov SI, offset DOS_VERSION
	add SI, 16
	call BYTE_TO_DEC
	mov AL, AH ; AH - DOS VERSION
	add SI, 3
	call BYTE_TO_DEC
	mov DX, offset DOS_VERSION
	call PRINT_MES_SYS

	mov SI, offset OEM_NUMBER
	add SI, 14
	mov AL, BH ; BH - OEM NUMBER
	call BYTE_TO_DEC
	mov DX, offset OEM_NUMBER
	call PRINT_MES_SYS

	mov DI, offset USER_NUMBER
	add DI, 15
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	mov DX, offset USER_NUMBER
	call PRINT_MES_SYS

	pop SI
	pop DI
	pop CX
	pop BX
	pop AX
	
	ret
PRINT_SYSTEM_VERSION ENDP

BEGIN:
	call PRINT_PC_TYPE
	call PRINT_SYSTEM_VERSION

	xor AL, AL
	mov AH, 4Ch
	int 21h

TESTPC ENDS
END START