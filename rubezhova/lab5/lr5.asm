ASTACK SEGMENT STACK
	DW 128 DUP(?)
ASTACK ENDS
DATA SEGMENT
	RESULT	DB 0
	SET_MSG DB 'Interrupt is set.', 0DH, 0AH,'$'
	NOT_SET_MSG DB 'Interrupt is not set.', 0DH, 0AH,'$'
	ALREADY_SET_MSG DB 'Interrupt has already set.', 0DH, 0AH,'$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:ASTACK
	
USR_INTERRUPT PROC FAR
		jmp starting
		KEEP_PSP	DW ?
		KEEP_IP 	DW ?
		KEEP_CS 	DW ?
		KEEP_SS 	DW ?
		KEEP_SP 	DW ?
		INT_ID  	DW 01212h
		SHIFT_CODE	DB 2Ah
		KEY_Z_CODE	DB 2Ch
		KEY_X_CODE	DB 2Dh
		KEY_PRINT	DB ?
		INT_STACK 	DW 128 dup(?)
		STACK_TOP 	DW ?
		
	starting:
		mov KEEP_SS, SS
        	mov KEEP_SP, SP
        	mov SP, CS
        	mov SS, SP
        	mov SP, OFFSET STACK_TOP
		push AX
        	push BX
        	push CX
		push ES
		
	in AL, 60h  ; to read scan-code from port
        cmp AL, SHIFT_CODE ; compare with scan-codes
        je shft
        
        cmp AL, KEY_Z_CODE
        je key_z
        
        cmp AL, KEY_X_CODE
        je key_x
        
        next_:
		je signal_to_kb
		call dword ptr CS:KEEP_IP
		jmp int_end
        shft:
        	mov KEY_PRINT, '!'
        	jmp next_
	key_z:
		mov KEY_PRINT, '@'
		jmp next_
	key_x:
		mov KEY_PRINT, '#'
		jmp next_
        
		
	signal_to_kb:
		in AL, 61h
		mov AH, AL
		or AL, 80h
		out 61h, AL
		xchg AH, AL
		out 61h, AL
		mov AL, 20h
		out 20h, AL
		
	print_key:
		mov AH, 05h ; function to write to buffer
		mov CL, KEY_PRINT
		
	to_buffer:
		mov CH, 00h
		int 16h
		or AL, AL ; check an overflow of buffer
		jmp int_end
	   
	reset_buffer:
		mov AX, 40h
		mov ES, AX
		mov AX, ES:[1Ah]
		mov ES:[1Ch], AX
		jmp print_key

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
		int_ending:
USR_INTERRUPT ENDP
; -------------------------------------------------------------------------
IS_SET PROC NEAR
	push AX
        push DX
        push SI
        
        mov RESULT, 1
        mov AH, 35h
        mov AL, 09h
        int 21h
        mov SI, OFFSET INT_ID
        sub SI, OFFSET USR_INTERRUPT
        mov DX, ES:[BX+SI]
        cmp DX, 01212h
        je yes_set
        mov RESULT, 0
		
	yes_set: 
        	pop SI
        	pop DX
        	pop AX
		ret
IS_SET ENDP
; -------------------------------------------
USR_INT_SET PROC NEAR
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
		
	mov DX, offset USR_INTERRUPT
	mov AX, seg USR_INTERRUPT
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	mov DX, offset int_ending
	mov CL,4
	shr DX,CL
	inc DX
	mov AX, CS
        sub AX, KEEP_PSP
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
USR_INT_SET ENDP
; -------------------------------------------------
USR_INT_UNLOAD PROC NEAR
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
	
	mov AX, ES:[offset KEEP_PSP]
	mov ES, AX
	mov DX, ES:[2Ch]
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
USR_INT_UNLOAD ENDP
; ---------------------------------
CHECK_COMMAND PROC NEAR
	push AX	
	mov RESULT, 0
        mov AL, ES:[82h]
        cmp AL, '/'
        jne no_parameter
        mov AL, ES:[83h]
        cmp AL, 'u'
        jne no_parameter
        mov AL, ES:[84h]
        cmp AL, 'n'
        jne no_parameter
        mov RESULT, 1	
		
	no_parameter: 
        	pop AX
        	ret
CHECK_COMMAND ENDP
; ---------------------------------
PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
; ---------------------------------
MAIN PROC FAR
	push DS
	xor AX, AX
	mov AX, DATA
        mov DS, AX
	
        mov KEEP_PSP, ES
        call CHECK_COMMAND
        cmp RESULT, 1
        je int_not_set

        call IS_SET
        cmp RESULT, 0
        je int_set
        mov DX, offset ALREADY_SET_MSG
        call PRINT
        jmp ending
		
	int_set:  
		mov DX, offset SET_MSG
        	call PRINT
        	call USR_INT_SET
        	jmp ending

	int_not_set:     
        	call IS_SET
        	cmp RESULT, 0
        	je not_set
        	call USR_INT_UNLOAD
	not_set:
        	mov DX, OFFSET NOT_SET_MSG
        	call PRINT

	ending:    
		pop DS
        	mov AH, 4Ch
        	int 21h
MAIN ENDP
CODE ENDS

END main
