ASTACK SEGMENT STACK
   DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
    already_load_str db 'Interruption was already loaded', 0DH, 0AH, '$'
    success_load_str db 'Loading of interruption went successfully', 0DH, 0AH, '$'
    not_load_str db 'Interruption isnt load', 0DH, 0AH, '$'
    restored_str db 'Interruption is restored now', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK

;------------------------------------
    PRINT_MESSAGE  PROC  NEAR
		push AX
		mov AH, 9
		int 21h
		pop AX
		ret
	PRINT_MESSAGE  ENDP
;------------------------------------

;------------------------------------
    SET_CURSOR PROC NEAR
        mov ah, 02h
        mov bh, 0h
        mov dh, 0h
        mov dl, 0h
        int 10h
        ret
    SET_CURSOR ENDP

    GET_CURSOR PROC NEAR
        mov ah, 03h
        mov bh, 0
        int 10h
        ret
    GET_CURSOR ENDP
;------------------------------------

;------------------------------------
    MY_INT PROC FAR
        jmp begin_proc
        counter db 'Interruption counter: 0000$'
        signature dw 7777h
        keep_ip dw 0
        keep_cs dw 0
		address_of_psp dw ?
        keep_ss dw 0
        keep_sp dw 0
        keep_ax dw 0
        my_stack dw 16 dup(?)

    begin_proc:
        mov keep_sp, SP
        mov keep_ax, AX
        mov AX, SS
        mov keep_ss, AX
        mov AX, keep_ax
        mov SP, offset begin_proc
        mov AX, seg my_stack
        mov SS, AX
        push AX 
        push CX 
        push DX

        call GET_CURSOR
        push DX
        call SET_CURSOR
        push SI
	    push CX
	    push DS
   	    push BP
        mov AX, seg counter
    	mov DS, AX
    	mov SI, offset counter
    	add SI, 21
       	mov CX, 4

    loop_for_count:
        mov BP, CX
        mov AH, [SI+BP]
        inc AH
        mov [SI+BP], AH
        cmp AH, 3ah
        jne for_print
        mov AH, 30h
        mov [SI+BP], AH
       	loop loop_for_count

    for_print:
       	pop BP
       	pop DS
       	pop CX
       	pop SI
    	push ES
    	push BP
    	mov AX, seg counter
    	mov ES,AX
    	mov AX, offset counter
    	mov BP,AX
    	mov AH, 13h 
    	mov AL, 00h
    	mov CX, 26
    	mov BH,0
    	int 10h
    	pop BP
    	pop ES
    	pop DX
    	mov AH,02h
    	mov BH,0h
    	int 10h

        pop DX 
        pop CX 
        pop AX 
        mov keep_ax, AX
        mov SP, keep_sp
        mov AX, keep_ss
        mov SS, AX
        mov AX, keep_ax
        mov AL, 20h	
        out 20h, AL	
        iret
    my_int_last:
    MY_INT ENDP
;------------------------------------

;------------------------------------
    CHECK_UPLOAD_KEY PROC NEAR
       	push AX
        push BP
        mov CL, 0h
        mov BP, 81h
       	mov AL, ES:[BP + 1]
       	cmp AL, '/'
       	jne exit
       	mov AL, ES:[BP + 2]
       	cmp AL, 'u'
       	jne exit
       	mov AL, ES:[BP + 3]
       	cmp AL, 'n'
       	jne exit
       	mov CL, 1h

    exit:
        pop BP
       	pop AX
       	ret
    CHECK_UPLOAD_KEY ENDP


    IF_ALREADY_LOAD PROC NEAR
        push AX
        push DX
        push ES
        push SI
        mov CL, 0h
        mov AH, 35h
        mov AL, 1ch
        int 21h
        mov SI, offset signature
        sub SI, offset MY_INT
        mov DX, ES:[BX+SI]
        cmp DX, signature
        jne if_end
        mov CL, 1h 

    if_end:
        pop SI
        pop ES
        pop DX
        pop AX
        ret
    IF_ALREADY_LOAD ENDP


    LOAD PROC NEAR
       	push AX
        push CX
       	push DX
       	call IF_ALREADY_LOAD
       	cmp CL, 1h
       	je already_load
        mov address_of_psp, ES
       	mov AH, 35h
    	mov AL, 1ch
    	int 21h
        mov keep_cs, ES
	    mov keep_ip, BX
    	push ES
        push BX
       	push DS
       	lea DX, MY_INT
       	mov AX, seg MY_INT
       	mov DS, AX
       	mov AH, 25h
       	mov AL, 1ch
       	int 21h
       	pop DS
        pop BX
        pop ES
        mov DX, offset success_load_str
       	call PRINT_MESSAGE
       	lea DX, my_int_last
       	mov CL, 4h
       	shr DX, CL
       	inc DX 
       	add DX, 100h
       	xor AX,AX
       	mov AH, 31h
       	int 21h
        jmp end_load

    already_load:
     	mov DX, offset already_load_str
        call PRINT_MESSAGE

    end_load:
       	pop DX
        pop CX
       	pop AX
       	ret
    LOAD ENDP


    UNLOAD PROC NEAR
       	push AX
       	push SI
       	call IF_ALREADY_LOAD
       	cmp CL, 1h
       	jne not_load
        cli
        push DS
        push ES
        mov AH, 35h
        mov AL, 1ch
        int 21h
        mov SI, offset keep_ip
	    sub SI, offset MY_INT
	    mov DX, ES:[BX+SI]
	    mov AX, ES:[BX+SI+2]
   	    mov DS, AX
        mov AH, 25h
        mov AL, 1ch
        int 21h
        mov AX, ES:[BX+SI+4]
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
        mov DX, offset restored_str
       	call PRINT_MESSAGE
        jmp end_unload

    not_load:
        mov DX, offset not_load_str
        call PRINT_MESSAGE

    end_unload:
       	pop SI
       	pop AX
       	ret
    UNLOAD ENDP
;------------------------------------

;------------------------------------
    MAIN PROC FAR
       	mov AX, DATA
       	mov DS, AX
        call CHECK_UPLOAD_KEY
        cmp CL, 0h
        jne unload_key
        call LOAD
        jmp end_main

    unload_key:
        call UNLOAD

    end_main:
        xor AL, AL
        mov AH, 4ch
        int 21h
    MAIN ENDP

CODE ENDS

END MAIN