AStack SEGMENT  STACK
	DW 64 DUP(?)   
AStack ENDS

DATA SEGMENT
	PARAMETERS	DB 14 dup(0)
	PATH	DB 64 dup(0)
	FILE	DB "lab2.COM", 0
	MEM_ERROR	DB 'Memory error        ',13,10,'$'
	LOAD_ERROR	DB 'Loading error        ',13,10,'$'
	NORM_EXIT		DB 13,10,'Normal exit     Code:    ',13,10,'$'
	CTRL_EXIT		DB 'Ctrl-C exit     ',13,10,'$'
	DEV_EXIT		DB 'Device error exit     ',13,10,'$'
	FUNC_EXIT		DB 'Function 31h exit     ',13,10,'$'
	KEEP_SS 	DW ?
	KEEP_SP 	DW ?
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

;-------------------------------------
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

;-------------------------------------	
	PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP

;-------------------------------------	
	FREE_UP_MEM PROC NEAR
		push AX
		push BX
		push DX
		push CX
   
		mov BX, offset end_address
		mov AX, ES
		sub BX, AX
		mov CL, 4
		shr BX, CL
		mov AH, 4Ah 
		int 21h
	
		jnc free_mem_end
		mov DX, offset MEM_ERROR
		call PRINT
		
		free_mem_end:
		pop CX
		pop DX
		pop BX
		pop AX
		ret
	FREE_UP_MEM ENDP
	
;-------------------------------------
	CREATE_PARAMETER_BLOCK PROC NEAR
		push AX
		push DI
		mov DI, offset PARAMETERS
		mov [DI+2], ES
		mov AX, 80h
		mov [DI+4], AX
		pop DI
		pop AX
		ret
	CREATE_PARAMETER_BLOCK ENDP
	
;-------------------------------------
	COMPOSE_PATH PROC NEAR
		push DX
		push DI
		push SI
		push ES
		
		mov ES, ES:[2Ch]
		mov SI, offset PATH
		xor DI, DI
		
		read_byte:
		mov DL, ES:[DI]
		check_byte:
		inc DI
		cmp DL, 0
		jne read_byte
		mov DL, ES:[DI]
		cmp DL, 0
		jne check_byte
		
		add DI, 3
		write_path:
		mov DL, ES:[DI]
		mov [SI], DL
		inc SI
		inc DI
		cmp DL, 0
		jne write_path
		
		backslash_loop:
		mov DL, [SI-2]
		dec SI
		cmp DL, '\'
		jne backslash_loop
		
		mov DI, offset FILE
		write_filename:
		mov DL, [DI]
		mov [SI], DL
		inc SI
		inc DI
		cmp DL, 0
		jne write_filename
		
		pop ES
		pop SI
		pop DI
		pop DX
		ret
	COMPOSE_PATH ENDP

;-------------------------------------	
	BEGIN PROC NEAR
		push AX
		push BX
		push DX
		push SI
		push ES
		
		mov KEEP_SS, SS
		mov KEEP_SP, SP
		mov AX, DS
		mov ES, AX
		mov BX, offset PARAMETERS
		mov DX, offset PATH

		mov AX, 4B00h
		int 21h
		mov SS, KEEP_SS
		mov SP, KEEP_SP
		
		mov DX, offset LOAD_ERROR
		jc print_exit_info
		
		loaded:
		mov AH, 4Dh
		int 21h
		mov DX, offset NORM_EXIT
		cmp AH, 0
		je read_key
		mov DX, offset CTRL_EXIT
		cmp AH, 1
		je print_exit_info
		mov DX, offset DEV_EXIT
		cmp AH, 2
		je print_exit_info
		mov DX, offset FUNC_EXIT
		cmp AH, 3
		je print_exit_info
		
		read_key:
		mov SI, DX
		add SI, 28
		call BYTE_TO_DEC
		
		print_exit_info:
		call PRINT

		pop ES
		pop SI
		pop DX
		pop BX
		pop AX
		ret
	BEGIN ENDP

;-------------------------------------
	Main PROC FAR
		sub AX, AX
		mov AX, DATA
		mov DS, AX

		call FREE_UP_MEM

		jc main_end
		call CREATE_PARAMETER_BLOCK
		call COMPOSE_PATH
		call BEGIN
		
		main_end:
		xor AL, AL
		mov AH, 4Ch
		int 21h
	Main ENDP

end_address:
CODE ENDS
end Main