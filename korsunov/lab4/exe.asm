MYSTACK SEGMENT STACK
   DW 200 DUP(?)
MYSTACK ENDS

DATA SEGMENT
    LOADED db 'Interruption is loaded', 0DH, 0AH, '$'
    LOADED_YES db 'Interruption loading is success', 0DH, 0AH, '$'
    LOADED_NO db 'Interruption loading is not success', 0DH, 0AH, '$'
    LOADED_RESTORED db 'Interruption is restored', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:MYSTACK

    WRITE_MESSAGE_WORD  PROC  near
		push AX
		
		mov AH, 9
		int 21h
		
		pop AX
		ret
	WRITE_MESSAGE_WORD  ENDP

    setCurs PROC near
        mov AH, 02h
        mov BH, 0h
        mov DH, 0h
        mov DL, 0h
        int 10h
        ret
    setCurs ENDP

    getCurs PROC near
        mov AH, 03h
        mov BH, 0
        int 10h
        ret
    getCurs ENDP

    INTERRUPT PROC far ;обработчик прерываний
        jmp begin
        counter db 'Interruption counter: 0000$'
        sign dw 7777h
        keep_IP dw 0 ; для хранения сегмента
        keep_CS dw 0 ; и смещения прерывания
		psp_address dw ?
        keep_SS dw 0
        keep_SP dw 0
        keep_AX dw 0
        my_stack dw 16 dup(?)

    begin:
        mov keep_SP, SP
        mov keep_AX, AX
        mov keep_SS, SS
		
        mov SP, offset begin
        mov AX, seg my_stack
        mov SS, AX
		
        push AX ;сохранение изменяемых регистров
        push CX 
        push DX

        call getCurs ;получение курсора
        push DX
		
        call setCurs ;установка курсора
        push SI
	    push CX
	    push DS
   	    push BP
		
        mov AX, seg counter
    	mov DS, AX
    	mov SI, offset counter
    	add SI, 21
       	mov CX, 4

    loop_count:
        mov BP, CX
        mov AH, [SI+BP]
        inc AH
        mov [SI+BP], AH
        cmp AH, 3ah
        jne print
        mov AH, 30h
        mov [SI+BP], AH
       	loop loop_count

	print:
    pop BP ; восстановление регистров
    pop DS
    pop CX
    pop SI
    push ES
    push BP
	
    mov AX, seg counter
    mov ES, AX
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
	
    mov AH,02h ; возвращение курсора
    mov BH,0h
    int 10h

    pop DX 
    pop CX 
    pop AX 
	
    mov keep_AX, AX
    mov SP, keep_SP
    mov AX, keep_SS
    mov SS, AX
    mov AX, keep_AX
    mov AL, 20h	
    out 20h, AL	
    iret
    INTERRUPT_last:
INTERRUPT ENDP

CHECK_UN PROC near
    push AX
    push BP
	
    mov CL, 0h
    mov BP, 81h
    mov AL, ES:[BP + 1]
    cmp AL, '/'
    jne finish
	
    mov AL, ES:[BP + 2]
    cmp AL, 'u'
    jne finish
	
    mov AL, ES:[BP + 3]
    cmp AL, 'n'
    jne finish
		
    mov CL, 1h

    finish:
        pop BP
       	pop AX
ret
CHECK_UN ENDP


IS_LOADED PROC near
    push AX
    push DX
    push ES
    push SI
	
    mov CL, 0h
    mov AH, 35h
    mov AL, 1ch
    int 21h
    mov SI, offset sign
    sub SI, offset INTERRUPT
    mov DX, ES:[BX+SI]
    cmp DX, sign
    jne if_end
    mov CL, 1h 

    if_end:
        pop SI
        pop ES
        pop DX
        pop AX
ret
IS_LOADED ENDP


LOAD PROC near
    push AX
    push CX
    push DX
	
    call IS_LOADED
    cmp CL, 1h
    je already_load
	
    mov psp_address, ES 
	;загрузка обработчика прерывания
    mov AH, 35h ; функция получения вектора
    mov AL, 1ch ; номер вектора
    int 21h
	
    mov keep_CS, ES ; запоминание сегмента
	mov keep_IP, BX ; и смещения
	
    push ES
    push BX
    push DS
	
	;настройка прерывания
    lea DX, INTERRUPT  ; смещение для процедуры в DX
    mov AX, seg INTERRUPT ; сегмент процедуры
    mov DS, AX  ; помещаем в DS
    mov AH, 25h ; функция установки вектора
    mov AL, 1ch ; номер вектора
    int 21h ;нменяем прерывание
	
    pop DS
    pop BX
    pop ES
	
    mov DX, offset LOADED_YES
    call WRITE_MESSAGE_WORD
    lea DX, INTERRUPT_last
    mov CL, 4h
    shr DX, CL
    inc DX 
    add DX, 100h
    xor AX,AX
    mov AH, 31h
    int 21h
    jmp end_load

    already_load:
     	mov DX, offset LOADED
        call WRITE_MESSAGE_WORD

    end_load:
       	pop DX
        pop CX
       	pop AX
ret
LOAD ENDP


UNLOAD PROC near
    push AX
    push SI
	
    call IS_LOADED
    cmp CL, 1h
    jne not_load
	
	;при выгрузке обработчика прерывания
    cli
	
    push DS
    push ES
    mov AH, 35h
    mov AL, 1ch
    int 21h ; восстанавливаем вектор
	
    mov SI, offset keep_IP
	sub SI, offset INTERRUPT
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
    mov DX, offset LOADED_RESTORED
    call WRITE_MESSAGE_WORD
    jmp end_unload

    not_load:
        mov DX, offset LOADED_NO
        call WRITE_MESSAGE_WORD

    end_unload:
       	pop SI
       	pop AX
    ret
    UNLOAD ENDP

    MAIN PROC far
		sub AX, AX
       	mov AX, DATA
       	mov DS, AX
		
        call CHECK_UN ;проверка на /un
        cmp CL, 0h
        jne un
        call LOAD ;загрузить
        jmp end_main

    un:
        call UNLOAD ;выгрузить

    end_main:
        xor AL, AL
        mov AH, 4ch
        int 21h
    MAIN ENDP

CODE ENDS

END MAIN