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
		KEEP_CS 	DW ?
		KEEP_IP 	DW ?
		KEEP_SS 	DW ?
		KEEP_SP 	DW ?
		INT_ID  	DW 0ABCDh
		COUNTER		DB 'Calls : 0000'
		INT_STACK 	DB 128 dup(?)
		
		int_start:
		mov KEEP_SS, SS
        mov KEEP_SP, SP
        mov SP, seg INTER
        mov SS, SP
        mov SP, OFFSET int_start
		push DS
        push ES
		push AX
        push BX
        push CX
        push DX
        push SI
        push BP

        mov AH, 03h
        mov BH, 0
        int 10h
        push DX

        mov AH, 02h
        mov BH, 0
		mov DL, 20h
        mov DH, 5h
        int 10h
		
        mov SI, SEG COUNTER
        mov DS, SI
        mov SI, OFFSET COUNTER
		add SI, 7
		
        mov CX, 4
		num_loop:  
			mov BP, CX
			mov AH, [SI+BP]
			inc AH
			mov [SI+BP], AH
			cmp AH, 3Ah
			jne num_loop_end
			mov AH, 30h
			mov [SI+BP], AH
			loop num_loop
		num_loop_end:   

        mov BP, SEG COUNTER
        mov ES, BP
        mov BP, OFFSET COUNTER
        mov AH, 13h
        mov AL, 1
        mov BH, 0
        mov CX, 12
        int 10h
        mov AH, 02h
        mov BH, 0
        pop DX
        int 10h

        pop BP
        pop SI 
        pop DX
        pop CX
        pop BX
		pop AX
		pop ES
        pop DS
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
        mov AL, 1Ch
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
		MOV AL, 1Ch
		INT 21h
		MOV KEEP_IP, BX
		MOV KEEP_CS, ES
		
		mov DX, offset INTER
		mov AX, seg INTER
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
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
		mov AL,1Ch
		int 21h
		mov DX, ES:[offset KEEP_IP]
		mov AX, ES:[offset KEEP_CS]
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
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