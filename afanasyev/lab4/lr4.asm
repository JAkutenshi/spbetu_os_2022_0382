CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK
	
	INTERRUPT PROC FAR
		jmp int_start
		PSP			DW ?
		KEEP_CS 	DW ?
		KEEP_IP 	DW ?
		KEEP_SS 	DW ?
		KEEP_SP 	DW ?
		INT_ID  	DW 0ABCDh
		COUNTER		DB 'Counts: 0000'
		INT_STACK 	DB 128 dup(?)
		
		int_start:
		mov KEEP_SS, SS
        mov KEEP_SP, SP
        mov SP, seg INTERRUPT
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
        cmp DX, 0ABCDh
        je loaded
        mov FLAG, 0
		
		loaded: 
        pop SI
        pop DX
		pop BX
        pop AX
		ret
	IS_LOADED ENDP
	
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
		
		mov DX, offset INTERRUPT
		mov AX, seg INTERRUPT
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
	
	CHECK_CMD_KEY PROC NEAR
		push AX	
		
		mov FLAG, 0
        mov AL, ES:[82h]
        cmp AL, '/'
        jne no_key
        mov AL, ES:[83h]
        cmp AL, 'u'
        jne no_key
        mov AL, ES:[84h]
        cmp AL, 'n'
        jne no_key
        mov FLAG, 1	
		
		no_key: 
        pop     AX
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
		mov AX, DATA
        mov DS, AX
		
        mov PSP, ES
        call CHECK_CMD_KEY
        cmp FLAG, 1
        je int_unload

        call IS_LOADED
        cmp FLAG, 0
        je int_load
        mov DX, OFFSET ALREADY_LOADED_MSG
        call PRINT
        jmp exit
		
		int_load:  
		mov DX, OFFSET LOADED_MSG
        call PRINT
        call LOAD_INT
        jmp exit

		int_unload:     
        call IS_LOADED
        cmp FLAG, 0
        je unloaded
        call UNLOAD_INT
		unloaded:
        mov DX, OFFSET UNLOADED_MSG
        call PRINT

		exit:    
		pop DS
        mov AH, 4Ch
        int 21h
	main ENDP
CODE ENDS

ASTACK SEGMENT STACK
	DW 128 DUP(?)
ASTACK ENDS

DATA SEGMENT
	FLAG			   DB 0
	LOADED_MSG		   DB 'Interrupt loaded!',0DH,0AH,'$'
	UNLOADED_MSG	   DB 'Interrupt unloaded!',0DH,0AH,'$'
	ALREADY_LOADED_MSG DB 'Interrupt already loaded!',0DH,0AH,'$'
DATA ENDS
END main
