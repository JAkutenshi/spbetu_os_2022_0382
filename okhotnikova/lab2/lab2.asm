TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ

NMEM db 'Not available memory:     h', 0Dh, 0Ah,'$'
ENVIROMENT db 'Enviroment:     h', 0Dh, 0Ah, '$'
TAIL db 'Tail: ', '$'
ENV_CT db 'Enviroment content: ', '$'
PATH db 'Path: ', '$'

;STRING db 'Значение регистра AX= ',0DH,0AH,'$'

;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
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
loop_bd: div CX
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
end_l: pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP
;-------------------------------

PRINT_STRING PROC near
mov AH, 09h
int 21h
ret
PRINT_STRING ENDP

PRINT_SYMBOL PROC near
push AX
mov AH, 02h
int 21h
pop AX
ret
PRINT_SYMBOL ENDP

PRINT_NMEM PROC near
mov AX, DS:[2h]
mov DI, offset NMEM
add DI, 25
call WRD_TO_HEX
mov DX, offset NMEM
call PRINT_STRING
ret
PRINT_NMEM ENDP

PRINT_ENV PROC near
mov AX, DS:[2Ch]
mov DI, offset ENVIROMENT
add DI, 15
call WRD_TO_HEX
mov DX, offset ENVIROMENT
call PRINT_STRING
ret
PRINT_ENV ENDP

PRINT_TAIL PROC near
mov CL, DS:[80h]
mov DX, offset TAIL
call PRINT_STRING
cmp CL, 0
je end_proc
mov DI, 81h

loop_proc:
mov DL, DS:[DI]
call PRINT_SYMBOL
inc DI
loop loop_proc

end_proc:
mov DL, 0DH
call PRINT_SYMBOL
mov DL, 0AH
call PRINT_SYMBOL
ret
PRINT_TAIL ENDP

PRINT_CONT PROC near
   mov ES, DS:[2Ch]
   xor DI, DI
   mov DX, offset ENV_CT
   call PRINT_STRING

label1:
   mov DL, ES:[DI]
   cmp DL, 0
   je end_proc2
   call PRINT_SYMBOL
   inc DI
   jmp label1

end_proc2:
   mov DL, 0DH  
   call PRINT_SYMBOL
   mov DL, 0AH
   call PRINT_SYMBOL
   inc DI
   mov DL, ES:[DI]
   cmp DL, 0
   jne label1
   ret
PRINT_CONT ENDP

PRINT_PATH PROC near
add DI, 3
mov DX, offset PATH
call PRINT_STRING

label_path:
mov DL, ES:[DI]
cmp DL, 0
je end_path
call PRINT_SYMBOL
inc DI
jmp label_path

end_path:
mov DL, 0DH
call PRINT_SYMBOL
mov DL, 0AH
call PRINT_SYMBOL
ret

PRINT_PATH ENDP

; КОД
BEGIN:
call PRINT_NMEM
call PRINT_ENV
call PRINT_TAIL
call PRINT_CONT
call PRINT_PATH
 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа