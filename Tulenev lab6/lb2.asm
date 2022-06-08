TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

UNAVAILABLE_MEMORY db 'Address of unavailable memory segment:     ', 0DH, 0AH, '$'
ENVIRONMENT db 'Address of environment segment:     ', 0DH, 0AH, '$'
CONTENT_ENV_AREA db 'Contents of environment area:   ', 0DH, 0AH, '$'
COMMAND_LINE_END_EMPTY db 'End of command line: empty', 0DH, 0AH, '$'
COMMAND_LINE_END db 'End of command line:$'
LOADED_MODULE_PATH db 'Path of loaded module:$'

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

WRITE_MESSAGE_WORD PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
WRITE_MESSAGE_WORD ENDP

WRITE_MESSAGE_BYTE PROC near
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
WRITE_MESSAGE_BYTE ENDP

PRINT_UNAVAILABLE_MEMORY PROC near
	push AX
	push DI
	push DX

	mov AX, DS:[02h]
	mov DI, offset UNAVAILABLE_MEMORY
	add DI, 42
	call WRD_TO_HEX
	mov DX, offset UNAVAILABLE_MEMORY

	call WRITE_MESSAGE_WORD
	
	pop DX
	pop DI
	pop AX

	ret
PRINT_UNAVAILABLE_MEMORY ENDP

PRINT_ENVIRONMENT PROC near
	push AX
	push DI
	push DX

	mov AX, DS:[02Ch]
	mov DI, offset ENVIRONMENT
	add DI, 35
	call WRD_TO_HEX
	mov DX, offset ENVIRONMENT

	call WRITE_MESSAGE_WORD

	pop DX
	pop DI
	pop AX

	ret
PRINT_ENVIRONMENT ENDP

PRINT_COMMAND_LINE_END PROC near
	push AX
	push DI
	push CX
	push DX

	xor CX, CX

	mov CL, DS:[80h]
	cmp CL, 0h
	je empty_cont
	xor DI, DI

	mov DX, offset COMMAND_LINE_END
	call WRITE_MESSAGE_WORD

	cycle:
		mov DL, DS:[81h+DI]
		call WRITE_MESSAGE_BYTE
		inc DI
	loop cycle
	mov DL, 0Dh
	call WRITE_MESSAGE_BYTE
	mov DL, 0Ah
	call WRITE_MESSAGE_BYTE
	jmp final
		
	empty_cont:
		mov DX, offset COMMAND_LINE_END_EMPTY
		call WRITE_MESSAGE_WORD

	final:
		pop DX
		pop CX
		pop DI
		pop AX
	ret
PRINT_COMMAND_LINE_END ENDP

PRINT_CONTENT_ENV_AREA_AND_LOADED_MODULE_PATH PROC near
	push AX
	push DI
	push DX
	push ES

	mov DX, offset CONTENT_ENV_AREA
	call WRITE_MESSAGE_WORD
	xor DI, DI
	mov AX, DS:[2Ch]
	mov ES, AX

	cycle_02:
		mov DL, ES:[DI]
		cmp DL, 0h
		je end_word
		call WRITE_MESSAGE_BYTE
		inc DI
		jmp cycle_02

	end_word:
		mov DL, 0Ah
		call WRITE_MESSAGE_BYTE
		inc DI
		mov DL, ES:[DI]
		cmp DL, 0h
		je final_02
		call WRITE_MESSAGE_BYTE
		inc DI
		jmp cycle_02
	
	final_02:
		mov DX, offset LOADED_MODULE_PATH
		call WRITE_MESSAGE_WORD
		add DI, 3
		cycle_03:
			mov DL, ES:[DI]
			cmp DL, 0h
			je final_03
			call WRITE_MESSAGE_BYTE
			inc DI
			jmp cycle_03

	final_03:
		pop ES
		pop DX
		pop DI
		pop AX
	ret
PRINT_CONTENT_ENV_AREA_AND_LOADED_MODULE_PATH ENDP

BEGIN:
	call PRINT_UNAVAILABLE_MEMORY
	call PRINT_ENVIRONMENT
	call PRINT_COMMAND_LINE_END
	call PRINT_CONTENT_ENV_AREA_AND_LOADED_MODULE_PATH

	xor AL, AL
	
	mov AH, 01h ;запросить с клавиатуры символ и поместить введенный символ в регистр AL
	int 21h
	
	mov AH, 4Ch
	int 21h
TESTPC ENDS
END START
