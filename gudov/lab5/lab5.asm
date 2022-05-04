Astack SEGMENT STACK
	DW 128 DUP(?)
Astack ENDS

DATA SEGMENT
	flag		DB 0
	msg_loaded		  DB '-INTERRUPT LOADED!-',0DH,0AH,'$'
	msg_unloaded	  DB '-INTERRUPT UNLOADED!-!',0DH,0AH,'$'
	msg_already DB '-INTERRUPT ALREADY LOADED!-',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:Astack

    ;ПРОЦЕДУРЫ
    ;-----------------------------------------------------	
    PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP
	;-----------------------------------------------------	
	INTER PROC FAR
		jmp int_start
		PSP			DW ?
		KEEP_IP 	DW ?
		KEEP_CS 	DW ?
		KEEP_SS 	DW ?
		KEEP_SP 	DW ?
		INT_ID  	DW 0ABCDh     
		STRING		DB 'a b c d e f $'
		STR_INDEX	DB 0
		CAPS_LOCK	DB 0
		REQ_KEY		DB 2Ah
		INT_STACK 	DW 128 dup(?)
		STACK_TOP 	DW ?
		
		int_start:
		mov KEEP_SS, SS
        mov KEEP_SP, SP
        mov SP, CS
        mov SS, SP
        mov SP, OFFSET STACK_TOP
		push AX
        push BX
        push CX
		push ES
		
		mov CAPS_LOCK, 0
        mov AX, 40h
        mov ES, AX
        mov AX, ES:[17h]
        and AX, 1000000b
        cmp AX, 0h
        je read_scan_code
        mov CAPS_LOCK, 1
		
		read_scan_code:
		in AL, 60h
		cmp AL, REQ_KEY
		je signal_to_keyboard
		call dword ptr CS:KEEP_IP
		jmp int_end
		
		signal_to_keyboard:
		in AL, 61h ;взять значение порта управления клавиатурой
		mov AH, AL ;сохранить его
		or AL, 80h ;установить бит разрешения для клавиатуры
		out 61h, AL ;и вывести его в управляющий порт
		xchg AH, AL ;извлечь исходное значение порта
		out 61h, AL ;и записать его обратно
		mov AL, 20h ;послать сигнал "конец прерывания"
		out 20h, AL ;контроллеру прерываний 8259
		
		print_letter:
		xor BX, BX
		mov BL, STR_INDEX
		mov AH, 05h
		mov CL, STRING[BX]
		cmp CL, '$'
		jne check_caps
		mov BL, 0
		mov Cl, STRING[0]		
		check_caps:
		cmp CAPS_LOCK, 0b
		je to_buffer
		cmp CL, ' '
		je to_buffer
		add CL, -32		
		to_buffer:
		mov CH, 00h
		int 16h
		or AL, AL
		jnz reset_buffer
		inc BL
		mov STR_INDEX, BL
		jmp int_end
	   
		reset_buffer:
		mov AX, 40h
		mov ES, AX
		mov AX, ES:[1Ah]
		mov ES:[1Ch], AX
		jmp print_letter

		int_end:
		pop ES
        pop CX
        pop BX
		pop AX
        mov SP, KEEP_SS
        mov SS, SP
        mov SP, KEEP_SP
        mov AL, 20h
		out 20h, AL
        iret
		int_last_byte:
	INTER ENDP
	;-----------------------------------------------------	
	IS_LOADED PROC NEAR
		push AX
		push BX
        push DX
        push SI		
        mov flag, 1
        mov AH, 35h
        mov AL, 09h
        int 21h
        mov SI, OFFSET INT_ID
        sub SI, OFFSET INTER
        mov DX, ES:[BX+SI]
        cmp DX, 0ABCDh
        je loaded
        mov flag, 0
		
		loaded: 
        pop SI
        pop DX
		pop BX
        pop AX
		ret
	IS_LOADED ENDP
	;-----------------------------------------------------	
	LOAD_INT PROC NEAR
		push DS
		push ES
		push AX
		push BX
		push CX
		push DX		
		MOV AH, 35h
		MOV AL, 09h
		INT 21h
		MOV KEEP_IP, BX
		MOV KEEP_CS, ES
		
		mov DX, offset INTER
		mov AX, seg INTER
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
		int 21h		
		mov DX, offset int_last_byte
		mov CL,4
		shr DX,CL
		inc DX
		mov AX, CS
        sub AX, PSP
        add DX, AX
        xor AX, AX
		mov AH,31h
		int 21h
		
		pop DX
		pop CX
		pop BX
		pop AX
		pop ES
		pop DS
		ret
	LOAD_INT ENDP
	;-----------------------------------------------------	
	UNLOAD_INT PROC NEAR
		push DS
		push ES
		push AX
		push BX
		push DX
		
		cli
		mov AH,35h
		mov AL,09h
		int 21h
		mov DX, ES:[offset KEEP_IP]
		mov AX, ES:[offset KEEP_CS]
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
		int 21h
		mov AX, ES:[offset PSP]
		mov ES, AX
		mov DX, ES:[2ch]
		mov AH, 49h
		int 21h
		mov ES, DX
		mov AH, 49h
		int 21h
		sti

		pop DX
		pop BX
		pop AX
		pop ES
		pop DS
		ret
	UNLOAD_INT ENDP
	;-----------------------------------------------------	
	CHECK PROC NEAR
		push AX	
		mov flag, 0
        mov AL, ES:[82h]
        cmp AL, '/'
        jne no_key
        mov AL, ES:[83h]
        cmp AL, 'u'
        jne no_key
        mov AL, ES:[84h]
        cmp AL, 'n'
        jne no_key
        mov flag, 1	
		
		no_key: 
        pop     AX
        ret
	CHECK ENDP
	;-----------------------------------------------------		
	main PROC FAR
		push DS
		xor AX, AX
		mov AX, DATA
        mov DS, AX
	
        mov PSP, ES
        call CHECK
        cmp flag, 1
        je int_unload
        call IS_LOADED
        cmp flag, 0
        je int_load
        mov DX, OFFSET msg_already
        call PRINT
        jmp final

		int_load:  
		mov DX, OFFSET msg_loaded
        call PRINT
        call LOAD_INT
        jmp final

		int_unload:     
        call IS_LOADED
        cmp flag, 0
        je unloaded
        call UNLOAD_INT
		unloaded:
        mov DX, OFFSET msg_unloaded
        call PRINT

		final:    
		pop DS
        mov AH, 4Ch
        int 21h
	main ENDP
CODE ENDS

END main