PRINT_TASK SEGMENT
	ASSUME CS:PRINT_TASK, DS:PRINT_TASK, ES:NOTHING, SS:NOTHING
	ORG 100H
START:	JMP  BEGIN
; Данные
UnMem DB 'Segment address of unavailable memory:     h', 0DH, 0AH, '$'
EnvAddr DB 'Segment address of the environment:     h', 0DH, 0AH, '$'
Tail DB 'Command line tail: ', '$'
EnvCont DB 'Environment area content: ', 0DH, 0AH, '$'
PathMod DB 'Path of the module: ', '$'

ZeroLength DB 'Command line tail has a zero length.', 0DH, 0AH, '$'

; Процедуры
TETR_TO_HEX PROC near
		and AL, 0Fh
		cmp AL, 09
		jbe NEXT
		add AL, 07
NEXT:	add AL, 30h
		ret
TETR_TO_HEX ENDP
; -------------------------------------------------------
; байт в AL переводится в два символа шестн. числа в AX
BYTE_TO_HEX	PROC near
		push CX
		mov AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov CL, 4
		shr AL, CL
		call TETR_TO_HEX
		pop CX
		ret
BYTE_TO_HEX ENDP
; -------------------------------------------------------
; перевод в 16 с/с 16-ти разрядного числа в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
		push BX
		mov BH, AH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		dec DI
		mov AL, BH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		pop BX
		ret
WRD_TO_HEX ENDP
; -------------------------------------------------------
; Основной код
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP

SYMB_PRINT PROC NEAR
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
SYMB_PRINT ENDP

SEG_ADDR1 PROC near
	mov ax, es:[02h]
	mov di, offset UnMem + 42
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset UnMem
	call PRINT
	ret

SEG_ADDR1 ENDP

SEG_ADDR2 PROC near
	mov ax, es:[2Ch]
	mov di, offset EnvAddr + 39
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset EnvAddr
	call PRINT
	ret
SEG_ADDR2 ENDP

TAIL_CL PROC near
	mov dx, offset Tail
	call PRINT
	mov cl, es:[80h] ; get a number of symbols in tail
	mov ch, 0 	; cleaning for correct loop-cycle
	cmp cl, 0
	je zero_length
	mov di, 81h
	
	label1:
		mov dl, es:[di]
		call SYMB_PRINT
		inc di
		loop label1
	pass:
		mov dl,0DH  
        	call SYMB_PRINT
   		mov dl,0AH
   		call SYMB_PRINT
   		ret
	zero_length:
		mov dx, offset ZeroLength
		call PRINT
		ret		
TAIL_CL ENDP

ENV_CONTENT PROC near
	mov dx, offset EnvCont
	call PRINT
	mov di, 2Ch
	mov es, ds:[di]
	xor di, di
	
	cycle:
        	mov dl, es:[di]
    		cmp dl, 0
    		je check_second_zero
	        call SYMB_PRINT
	        inc di
    		jmp cycle
	check_second_zero:
		mov dl, 0Dh
		call SYMB_PRINT
   		mov dl,0Ah
   		call SYMB_PRINT
   		inc di
   		mov dl, es:[di]
    		cmp dl, 0
    		jne cycle
   		ret	
ENV_CONTENT ENDP
	
PATH_MOD PROC near
	add di, 3
	mov dx, offset PathMod
	call PRINT
	
	cycle2:
		mov dl, es:[di]
		cmp dl, 0
		je end_string
		call SYMB_PRINT
		inc di
		jmp cycle2
	end_string:
		mov dl, 0Dh
		call SYMB_PRINT
		mov dl, 0Ah
		call SYMB_PRINT
		ret
PATH_MOD ENDP
	
; --------------------------------------------------
BEGIN:
	call SEG_ADDR1
	call SEG_ADDR2
	call TAIL_CL
	call ENV_CONTENT
	call PATH_MOD
; Вызов функции DOS ввода с клавиатуры
	xor AL, AL
	mov AH, 01h
	int 21h	
; Выход в DOS
	mov AH, 4Ch
	int 21h

PRINT_TASK ENDS
END START
