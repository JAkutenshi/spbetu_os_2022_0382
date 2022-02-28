TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Данные
UNVALIABLE_MEMORY db 'Locked memory address:     h',13,10,'$'
ENVIRONMENT_ADRESS db 'Environment address:     h',13,10,'$'
CMD_TAIL db 'Command line tail:        ',13,10,'$'
NULL_TAIL db 'In Command tail no sybmols',13,10,'$'
CONTENT db 'Content:',13,10, '$'
END_STRING db 13, 10, '$'
PATH db 'Patch:  ',13,10,'$'

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
   mov AH,09h
   int 21h
   ret
PRINT ENDP
;-------------------------------

GET_UNVALIABLE_MEMORY PROC near
   mov ax,ds:[02h]
   mov di, offset UNVALIABLE_MEMORY
   add di, 26
   call WRD_TO_HEX
   mov dx, offset UNVALIABLE_MEMORY
   call PRINT
   ret
GET_UNVALIABLE_MEMORY ENDP

GET_ENVIRONMENT_ADRESS  PROC near 
   mov ax,ds:[2Ch]
   mov di, offset PSP_MEMORY
   add di, 24
   call WRD_TO_HEX
   mov dx, offset ENVIRONMENT_ADRESS
   call PRINT
   ret
GET_ENVIRONMENT_ADRESS ENDP

GET_CMD_TAIL PROC near   
   xor cx, cx
	mov cl, ds:[80h]
	mov si, offset CMD_TAIL
	add si, 19
   cmp cl, 0h
   je empty_tail
	xor di, di
	xor ax, ax
readtail: 
	mov al, ds:[81h+di]
   inc di
   mov [si], al
	inc si
	loop readtail
	mov dx, offset CMD_TAIL
	jmp end_tail
empty_tail:
		mov dx, offset NULL_TAIL
end_tail: 
   call PRINT 
   ret
GET_CMD_TAIL ENDP

GET_CONTENT PROC near
   mov dx, offset CONTENT
   call PRINT
   xor di,di
   mov ds, ds:[2Ch]
read_string:
	cmp byte ptr [di], 00h
	jz end_str
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp find_end
end_str:
   cmp byte ptr [di+1],00h
   jz find_end
   push ds
   mov cx, cs
	mov ds, cx
	mov dx, offset END_STRING
	call PRINT
	pop ds
find_end:
	inc di
	cmp word ptr [di], 0001h
	jz read_path
	jmp read_string
read_path:
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call PRINT
	pop ds
	add di, 2
loop_path:
	cmp byte ptr [di], 00h
	jz complete
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp loop_path
complete:
	ret
GET_CONTENT ENDP

; Код
BEGIN:
   call GET_UNVALIABLE_MEMORY
   call GET_ENVIRONMENT_ADRESS
   call GET_CMD_TAIL
   call GET_CONTENT

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START