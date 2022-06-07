CODE SEGMENT
	ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	ORG 100H
	START: jmp BEGIN
	
	FREE_MEM DB "Available memory size:         bytes",0DH,0AH,'$'
	EXP_MEM  DB "Expanded memory size:          bytes",0DH,0AH,'$'
	MCB 	 DB "MCB:0   Adress:       PSP adress:       Size:          SD/SC: $"
	MEM_FAIL DB "Memory allocation failed",0DH,0AH,'$'
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
	
	BYTE_TO_DEC PROC NEAR
		push CX
		push DX
		xor AH,AH
		xor DX,DX
		mov CX,10
		loop_bd: div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_bd
		cmp AL,00h
		je end_l
		or AL,30h
		mov [SI],AL
		end_l: pop DX
		pop CX
		ret
	BYTE_TO_DEC ENDP
	
	SIZE_TO_DEC PROC NEAR
		push AX
		push BX
		push DX
		push SI
		add SI, 7
		mov BX,10h
		mul BX
		mov BX,10
		write_loop:
			div BX
			or dl,30h
			mov [SI], dl
			dec SI
			xor DX,DX
			cmp AX,0h
			jnz write_loop 
		pop SI
		pop DX
		pop BX
		pop AX
		ret
	SIZE_TO_DEC ENDP
	
	PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP
	
	PRINT_MEM PROC NEAR
		push AX
		push BX
		push DX
		push SI
		
		mov AH, 4Ah
		mov BX, 0FFFFh
		int 21h
		mov AX, BX
		mov DX, offset FREE_MEM
		mov SI, DX
		add SI, 22
		call SIZE_TO_DEC
		call PRINT
		
		mov AL, 30h
		out 70h, AL
		in AL, 71h
		mov BL, AL
		mov AL, 31h
		out 70h, AL
		in AL, 71h
		mov BH, AL
		mov AX, BX
		mov DX, offset EXP_MEM
		mov SI, DX
		add SI, 22
		call SIZE_TO_DEC
		call PRINT
		
		pop SI
		pop DX
		pop BX
		pop AX
		ret
	PRINT_MEM ENDP
	
	PRINT_MCB PROC NEAR
		push AX
		push BX
		push CX
		push DX
		push DI
		push SI
   
		mov AH, 52h
		int 21h
		mov AX, ES:[BX-2]
		mov ES, AX
		xor CX,CX

		MCB_block:
			inc CX
			mov AL, CL
			mov DX, offset MCB
			mov SI, DX
			add SI, 5
			call BYTE_TO_DEC

			mov AX, ES
			mov DI, SI
			add DI, 14
			call WRD_TO_HEX
			
			mov AX, ES:[1]
			add DI, 21
			call WRD_TO_HEX
			
			mov AX, ES:[3]	
			mov SI, DI
			add SI, 11
			call SIZE_TO_DEC
			call PRINT
			
			xor DI,DI
			write_char:
			mov DL, ES:[DI+8]
			mov AH, 02h
			int 21h
			inc DI
			cmp DI, 8
			jl write_char
			mov DX, offset NEWLINE
			call PRINT
			
			mov AL, ES:[0]
			cmp AL, 4Dh
			jne exit
			mov BX, ES
			add BX, ES:[3]
			inc BX
			mov ES, BX
			jmp MCB_block
		exit:
		pop SI
		pop DI
		pop DX
		pop CX
		pop BX
		pop AX
		ret
	PRINT_MCB ENDP
	
	FREE_UP_MEM PROC NEAR
		push AX
		push BX
		push DX
   
		mov AX, offset end_address
		mov BX, 10h
		xor DX,DX
		div BX
		add AX, 4
		mov BX, AX
		mov AH, 4Ah
		int 21h
   
		pop DX
		pop BX
		pop AX
		ret
	FREE_UP_MEM ENDP
	
	REQ_MEM PROC near
		push AX
		push BX
		push DX
   
		mov BX, 1000h
		mov AH, 48h
		int 21h
		jnc exit_
		mov DX, offset MEM_FAIL
		call PRINT
		
		exit_:
		pop DX
		pop BX
		pop AX
		ret
	REQ_MEM ENDP
	
	BEGIN:
		call PRINT_MEM
		call FREE_UP_MEM
		call REQ_MEM
		call PRINT_MCB
		xor AL,AL
		mov AH, 4Ch
		int 21H
end_address:
CODE ENDS
END START