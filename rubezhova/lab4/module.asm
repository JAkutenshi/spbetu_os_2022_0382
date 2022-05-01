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
	KEEP_CS 	DW ?
	KEEP_IP 	DW ?
	KEEP_SS 	DW ?
	KEEP_SP 	DW ?
	INT_ID  	DW 1212h
	COUNTER	DB 'IntNum: 0000'
	INT_STACK 	DB 128 dup(?)
	
	starting:
		mov KEEP_SS, SS
		mov KEEP_SP, SP
        	mov SP, seg USR_INTERRUPT
        	mov SS, SP
        	mov SP, OFFSET starting
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
	
	cycle1:  
		mov BP, CX
		mov AH, [SI+BP]
		inc AH
		mov [SI+BP], AH
		cmp AH, 3Ah
		jne cycle_end
		mov AH, 30h
		mov [SI+BP], AH
		loop cycle1
		
	cycle_end:   
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
	
	int_ending:
USR_INTERRUPT ENDP
	
; -------------------------------------------------------------------------
IS_SET PROC NEAR
	push AX
	push BX
        push DX
        push SI
        
        mov RESULT, 1
        mov AH, 35h
        mov AL, 1Ch
        int 21h
        mov SI, OFFSET INT_ID
        sub SI, OFFSET USR_INTERRUPT
        mov DX, ES:[BX+SI]
        cmp DX, 1212h
        je yes_set
        mov RESULT, 0
		
	yes_set: 
        	pop SI
        	pop DX
		pop BX
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
	MOV AL, 1Ch
	INT 21h
	MOV KEEP_IP, BX
	MOV KEEP_CS, ES
		
	mov DX, offset USR_INTERRUPT
	mov AX, seg USR_INTERRUPT
	mov DS, AX
	mov AH, 25h
	mov AL, 1Ch
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
	mov AL,1Ch
	int 21h
	mov DX, ES:[offset KEEP_IP]
	mov AX, ES:[offset KEEP_CS]
	mov DS, AX
	mov AH, 25h
	mov AL, 1Ch
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
