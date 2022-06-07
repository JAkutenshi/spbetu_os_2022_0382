TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:TESTPC, SS:TESTPC
   ORG 100H
START: JMP BEGIN

; Данные
adrMem db 'Inaccessable memory:     h ', 0DH, 0AH, '$'
adrEnv db 'Enviroment Address:     h', 0DH, 0AH, '$'
tail db 'Tail: ', '$'
contEnv db 'Enviroment contein:', 0DH, 0AH, '$'
path db 'Path:', 0DH, 0AH, '$'
EOL db 0DH, 0AH, '$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
PRINT PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
PRINT ENDP

ADR_MEM PROC near
	mov ax, ds:[2]
	mov di, offset adrMem
	add di, 24
	call WRD_TO_HEX
	mov dx, offset adrMem
	call PRINT 
	ret
ADR_MEM ENDP

ADR_ENV PROC near
	mov ax, ds:[44]
	mov di, offset adrEnv
	add di, 23
	call WRD_TO_HEX
	mov dx, offset adrEnv
	call PRINT
	ret
ADR_ENV ENDP

_TAIL PROC near
	mov cl, ds:[80h]
	mov dx, offset tail
	call PRINT
	cmp cl, 0
	je out_1
	
	mov si, 81h
	
	m1:
	mov dl, ds:[si]
	mov ah, 02h
	int 21h
	inc si
	LOOP M1
		
	out_1:
	mov dx, offset EOL
	call PRINT
	ret
	
_TAIL ENDP

CONT_ENV PROC near
	mov es, ds:[44]
	MOV DX, offset contEnv
	call PRINT
	
	xor di, di
	
next_str:	
	mov dl, es:[di] 
	cmp dl, 0h
	je final_1
	mov ah, 02h
	int 21h
	inc di
	jmp next_str
	
final_1:
	mov dx, offset EOL
	call PRINT
	inc di
	mov dl, es:[di] 
	cmp dl, 0h
	jne next_str
	ret
CONT_ENV ENDP

_PATH PROC near
	mov es, ds:[44]
	MOV DX, offset path
	call PRINT
	
	
	xor di, di
	
next_ind:	
	mov dl, es:[di] 
	cmp dl, 0h
	je final_2
	inc di
	jmp next_ind
	
final_2:
	inc di
	mov dl, es:[di] 
	cmp dl, 0h
	jne next_ind
	
	add di, 3
next_simbol:	
	mov dl, es:[di] 
	cmp dl, 0h
	je final_3
	mov ah, 02h
	int 21h
	inc di
	jmp next_simbol
	
final_3:
	mov dx, offset EOL
	call PRINT
	

	ret
_PATH ENDP


; Код
BEGIN:
   call ADR_MEM
   call ADR_ENV
   call _TAIL
   call CONT_ENV
   call _PATH
   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START 