ASTACK SEGMENT STACK
   DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
    str_int_already_loaded db 'Interruption is already loaded', 0DH, 0AH, '$'
    str_int_loaded_successfully db 'Interruption is loaded successfully', 0DH, 0AH, '$'
    str_int_is_not_loaded db 'Interruption is not loaded', 0DH, 0AH, '$'
    str_int_restored db 'Interruption is restored', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK

;-------------------------------------------
    PRINT_MESSAGE PROC NEAR
        push AX
        mov AH, 9
        int 21h
        pop AX
        ret
    PRINT_MESSAGE ENDP
;-------------------------------------------

;-------------------------------------------
    MY_INT PROC FAR
        jmp int_start
        KEY db 0h
        SHIFT db 0
        int_signature dw 7777h
        keep_ip dw 0
        keep_cs dw 0		
		psp_address dw ?
        keep_ss dw 0
        keep_sp dw 0
        keep_ax dw 0
        int_stack dw 64 dup(?)

    int_start:
        mov keep_sp, SP
        mov keep_ax, AX
        mov AX, SS
        mov keep_ss, AX
        mov SP, OFFSET int_start
        mov AX, seg int_stack
        mov SS, AX
        mov AX, keep_ax
        push AX 
        push CX 
        push DX 
		push ES
        mov KEY, 0h
        mov SHIFT, 0h
        mov AX, 40h
        mov ES, AX
        mov AX, ES:[17h]
        and AX, 11b
        cmp AX, 0h
        je read_new_symbol
        mov SHIFT, 1h

    read_new_symbol:
        in AL, 60h 
        cmp AL, 10h
        je symbol_q 
        cmp AL, 19h
        je symbol_p
        mov KEY, 1h
        jmp int_end

    symbol_q:
        mov AL, 'p'
        jmp change
    
    symbol_p:
        mov AL, 'q'
        jmp change

    change:
        push AX
        in AL, 61H
        mov AH, AL
        or AL, 80h
        out 61H, AL
        xchg AH, AL 
        out 61H, AL 
        mov AL, 20H 
        out 20H, AL 
        pop AX
        cmp SHIFT, 0h
        je write_key
        sub AL, 20h
        
    write_key:
        mov AH, 05h 
        mov CL, AL 
        mov CH, 00h 
        int 16h 
        or AL, AL 
        jz int_end 
        mov AX, 0040h
        mov ES, AX
        mov AX, ES:[1ah]
        mov ES:[1ch], AX
        jmp write_key

    int_end:
		pop ES
        pop DX 
        pop CX 
        pop AX 
        mov SP, keep_sp
        mov AX, keep_ss
        mov SS, AX
        mov AX, keep_ax
        mov AL, 20h	
        out 20h, AL	
        cmp KEY, 1h
        jne int_iret
        jmp dword ptr CS:[keep_ip] 

    int_iret:
        iret 

    MY_INT ENDP
    int_last:
;-------------------------------------------

;-------------------------------------------
    CHECK_UN PROC near
       	push AX
        push BP
        mov CL, 0h
        mov BP, 81h
       	mov AL,ES:[BP + 1]
       	cmp AL,'/'
       	jne final
       	mov AL,ES:[BP + 2]
       	cmp AL,'u'
       	jne final
       	mov AL,ES:[BP + 3]
       	cmp AL,'n'
       	jne final
       	mov CL, 1h

    final:
        pop BP
       	pop AX
       	ret
    CHECK_UN ENDP

    IS_LOAD PROC NEAR
        push AX
        push DX
        push ES
        push SI
        mov CL, 0h
        mov AH, 35h
        mov AL, 09h
        int 21h
        mov SI, offset int_signature
        sub SI, offset MY_INT
        mov DX, ES:[BX + SI]
        cmp DX, int_signature
        jne finish_check_load
        mov CL, 1h 

    finish_check_load:
        pop SI
        pop ES
        pop DX
        pop AX
        ret
    IS_LOAD ENDP
;-------------------------------------------

;-------------------------------------------
    LOAD_INT PROC near
       	push AX
        push CX
       	push DX
       	call IS_LOAD
       	cmp CL, 1h
       	je already_loaded
        mov psp_address, ES
       	mov AH, 35h
    	mov AL, 09h
    	int 21h
        mov keep_cs, ES
	    mov keep_ip, BX
    	push ES
        push BX
       	push DS
       	lea DX, MY_INT
       	mov AX, SEG MY_INT
       	mov DS, AX
       	mov AH, 25h
       	mov AL, 09h
       	int 21h
       	pop DS
        pop BX
        pop ES
        mov DX, offset str_int_loaded_successfully
       	call PRINT_MESSAGE
       	lea DX, int_last
       	mov CL, 4h
       	shr DX, CL
       	inc DX
       	add DX, 100h
       	xor AX,AX
       	mov AH, 31h
       	int 21h
        jmp finish_load

    already_loaded:
     	mov DX, offset str_int_already_loaded
        call PRINT_MESSAGE

    finish_load:
       	pop DX
        pop CX
       	pop AX
       	ret
    LOAD_INT ENDP

    UNLOAD_INT PROC near
       	push AX
       	push SI
       	call IS_LOAD
       	cmp CL, 1h
       	jne not_loaded
        cli
        push DS
        push ES
        mov AH, 35h
        mov AL, 09h
        int 21h
        mov SI, offset keep_ip
	    sub SI, offset MY_INT
	    mov DX, ES:[BX + SI]
	    mov AX, ES:[BX + SI + 2]
   	    mov DS, AX
        mov AH, 25h
        mov AL, 09h
        int 21h
        mov AX, ES:[BX + SI + 4]
   	    mov ES, AX
   	    push ES
       	mov AX, ES:[2ch]
       	mov ES, AX
       	mov AH, 49h
       	int 21h
       	pop ES
       	mov AH, 49h
       	int 21h
        pop ES
        pop DS
        sti
        mov DX, offset str_int_restored
       	call PRINT_MESSAGE
        jmp finish_unload

    not_loaded:
        mov DX, offset str_int_is_not_loaded
        call PRINT_MESSAGE

    finish_unload:
       	pop SI
       	pop AX
       	ret
    UNLOAD_INT ENDP
;-------------------------------------------

;-------------------------------------------
    MAIN PROC FAR
       	mov AX, DATA
       	mov DS, AX
        call CHECK_UN
        cmp CL, 0h
        jne un_unload
        call LOAD_INT
        jmp finish_main

    un_unload:
        call UNLOAD_INT

    finish_main:
        xor AL, AL
        mov AH, 4ch
        int 21h
    MAIN ENDP

CODE ENDS
END MAIN