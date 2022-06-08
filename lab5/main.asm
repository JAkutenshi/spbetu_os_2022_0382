ASTACK SEGMENT STACK
	DB 256 DUP(?)
ASTACK ENDS

DATA SEGMENT
	FLAG db 0
	LOADED_MES db 'Interrupt is loaded!', 0DH, 0AH,'$'
	UNLOADED_MES db 'Interrupt is unloaded!', 0DH, 0AH,'$'
	ALREADY_LOADED_MES db 'Interrupt is already loaded!', 0DH, 0AH,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK
	
	INTERRUPT PROC FAR
		jmp int_start
		SYMBOL DB 0
		INT_ID DW 1f17h
		KEEP_IP DW 0
		KEEP_CS DW 0
		PSP DW 0
		KEEP_AX DW 0
		KEEP_SS DW 0
		KEEP_SP DW 0

		INT_STACK DB 128 dup(?)
		
		int_start:
			mov KEEP_AX, AX
			mov KEEP_SS, SS
        		mov KEEP_SP, SP
        		mov SP, SEG INTERRUPT
        		mov SS, SP
        		mov SP, OFFSET int_start
			push ax
			push bx
			push cx
			push dx

			in al, 60h
			cmp al, 3bh
			je if_f1
			cmp al, 3ch
			je if_f2
			cmp al, 14h
			je if_T
			call dword ptr CS:KEEP_IP
			jmp int_end

			if_f1:
				mov SYMBOL, '1'
				jmp next_key
			if_f2:
				mov SYMBOL, '5'
				jmp next_key
			if_T:
				mov SYMBOL, '9'

			next_key:
				in al, 61h
				mov ah, al
				or al, 80h
				out 61h, al
				xchg al, al
				out 61h, al
				mov al, 20h
				out 20h, al

			print_key:
				mov ah, 05h
				mov cl, SYMBOL
				mov ch, 00h
				int 16h
				or al, al
				jz int_end
				mov ax, 40h
				mov es, ax
				mov ax, es:[1ah]
				mov es:[1ch], ax
				jmp print_key

			int_end:	
				pop dx
				pop cx
				pop bx
				pop ax

				mov sp, KEEP_SP
				mov ax, KEEP_SS
				mov ss, ax
				mov ax, KEEP_AX
				mov al, 20h
				out 20h, al
				iret

			if_end_byte:
	INTERRUPT ENDP
	
	IS_LOADED PROC NEAR
		push AX
		push BX
        	push DX
        	push SI
		
		mov FLAG, 1
		mov AH, 35h
		mov AL, 1Ch
		int 21h
		mov SI, OFFSET INT_ID
		sub SI, OFFSET INTERRUPT
		mov DX, ES:[BX+SI]
		cmp DX, 1f17h
		je if_loaded
		mov FLAG, 0
			
		if_loaded: 
			pop SI
			pop DX
			pop BX
			pop AX
		ret
	IS_LOADED ENDP
	
	LOAD_INT PROC NEAR
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES
		
		MOV AH, 35h
		MOV AL, 1Ch
		int 21h
		MOV KEEP_IP, BX
		MOV KEEP_CS, ES
		
		mov DX, offset INTERRUPT
		mov AX, seg INTERRUPT
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
		int 21h
		
		mov DX, offset if_end_byte
		mov CL, 4
		shr DX, CL
		inc DX
		mov AX, CS
        	sub AX, PSP
        	add DX, AX
        	xor AX, AX
		mov AH, 31h
		int 21h
		
		pop ES
		pop DS
		pop DX
		pop CX
		pop BX
		pop AX
		ret
	LOAD_INT ENDP
	
	UNLOAD_INT PROC NEAR
		cli
		push AX
		push BX
		push DX
		push DS
		push ES
		push SI
		
		mov AH, 35h
		mov AL, 1Ch
		int 21h
		mov SI, OFFSET KEEP_IP
		sub SI, OFFSET INTERRUPT
		mov DX, ES:[BX+SI]
		mov AX, ES:[BX+SI+2]
		
		push DS
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
		int 21h
		pop DS
		
		mov AX, ES:[BX+SI+4]
		mov ES, AX
		push ES
		mov AX, ES:[2Ch]
		mov ES, AX
		mov AH, 49h
		int 21h
		pop ES
		mov AH, 49h
		int 21h
		sti
		
		pop SI
		pop ES
		pop DS
		pop DX
		pop BX
		pop AX
		ret
	UNLOAD_INT ENDP
	
	CHECK_CMD_KEY PROC NEAR
		push AX	
		
		mov FLAG, 0
        	mov AL, ES:[82h]
        	cmp AL, '/'
		jne if_no_key
		mov AL, ES:[83h]
		cmp AL, 'u'
		jne if_no_key
		mov AL, ES:[84h]
		cmp AL, 'n'
		jne if_no_key
		mov FLAG, 1	
			
		if_no_key: 
			pop AX
			ret
	CHECK_CMD_KEY ENDP
	
	PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP
	
	main PROC FAR
		push DS
		xor AX, AX
		push AX
		mov AX, DATA
        	mov DS, AX
		
		mov PSP, ES
		call CHECK_CMD_KEY
		cmp FLAG, 1
		je int_unload

		call IS_LOADED
		cmp FLAG, 0
		je int_load
		mov DX, OFFSET ALREADY_LOADED_MES
		call PRINT
		jmp exit
			
		int_load:  
			mov DX, OFFSET LOADED_MES
			call PRINT
			call LOAD_INT
			jmp exit

		int_unload:     
			call IS_LOADED
			cmp FLAG, 0
			je unloaded
			call UNLOAD_INT
			
		unloaded:
			mov DX, OFFSET UNLOADED_MES
			call PRINT

		exit:    
			xor AL, AL
			mov AH, 4Ch
			int 21h
	main ENDP
CODE ENDS
	END main
