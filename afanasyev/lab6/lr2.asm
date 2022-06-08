CODE SEGMENT
	ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	ORG 100H
	START: jmp BEGIN
	
	MEM_SEG	 DB "External memory segment:     h",0DH,0AH,'$'
	ENV_SEG  DB "Environment segment:     h",0DH,0AH,'$'
	CMD_TAIL DB "Command-line tail:",'$'
	ENV_VARS DB "Environment variables: ",0DH,0AH,'$'
	PR_PATH	 DB "Program path: ",'$'
	NEWLINE	 DB 0DH,0AH,'$'
	
	TETR_TO_HEX PROC NEAR
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
		next: add AL,30h
		ret
	TETR_TO_HEX ENDP
	
	BYTE_TO_HEX PROC NEAR
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX
		pop CX
		ret
	BYTE_TO_HEX ENDP
	
	WRD_TO_HEX PROC NEAR
		push BX
		mov BH,AH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		dec DI
		mov AL,BH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		pop BX
		ret
	WRD_TO_HEX ENDP
	
	PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP
	
	PRINT_INFO PROC NEAR
		push AX
		push CX
		push DX
		push DI
		push ES
	;External memory segment
		mov DX, offset MEM_SEG
		mov DI, DX
		add DI, 28
		mov AX, CS:[2]
		call WRD_TO_HEX
		call PRINT
	;Environment segment
		mov DX, offset ENV_SEG
		mov DI, DX
		add DI, 24
		mov AX, CS:[2Ch]
		call WRD_TO_HEX
		call PRINT
	;Command-line tail
		mov DX, offset CMD_TAIL
		call PRINT
		xor CX,CX
		mov CL, CS:[80h]
		cmp CL, 0
		mov AH, 02h
		je lend
		mov DI, 81h
		lstart:
			mov DL, CS:[DI]
			int 21h
			inc DI
			loop lstart
		lend:
		mov DX, offset NEWLINE
		call PRINT
	;Environment variables
		mov DX, offset ENV_VARS
		call PRINT
		mov DX, CS:[2Ch]
		mov ES, DX
		mov DI, 0
		_next:
			mov DL, ES:[DI]
		_print:
			int 21h
			inc DI
			cmp DL, 0
			jne _next
			mov DX, offset NEWLINE
			call PRINT
			mov DL, ES:[DI]
			cmp DL, 0
			jne _print
	;Program path
		mov DX, offset PR_PATH
		call PRINT
		add DI, 3
		__next:
			mov DL, ES:[DI]
			int 21h
			inc DI
			cmp DL, 0
			jne __next
		mov DX, offset NEWLINE
		call PRINT
		pop ES
		pop DI
		pop DX
		pop CX
		pop AX
		ret
	PRINT_INFO ENDP
	
	BEGIN:
		call PRINT_INFO
		
		mov AH, 1
		int 21h
		
		mov AH,4Ch
		int 21H
CODE ENDS
END START