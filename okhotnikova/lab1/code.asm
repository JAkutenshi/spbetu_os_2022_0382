TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ

PC db 'PC type: PC ', 0DH, 0AH, '$'
PC_XT db 'PC type: PC/XT ', 0DH, 0AH, '$'
AT db 'PC type: AT ', 0DH, 0AH, '$'
PS230 db 'PC type: PS2 model 30 ', 0DH, 0AH, '$'
PS25060 db 'PC type: PS2 model 50 or 60 ', 0DH, 0AH, '$'
PS280 db 'PC type: PS2 model 80 ', 0DH, 0AH, '$'
PCjr db 'PC type: PSCjr ', 0DH, 0AH, '$'
PC_convert db 'PC type: PC Convertible ', 0DH, 0AH, '$'
DOS_vs db 'MS DOS version:  .  ', 0DH, 0AH, '$'
OEM_num db 'OEM number:   ', 0DH, 0AH, '$'
USER_num db 'User number:       ', 0DH, 0AH, '$'

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

PCTYPE_CHECKING PROC near
mov AX, 0F000h
mov ES, AX
mov AL, ES:[0FFFEh] ;получаем байт

cmp AL, 0FFh
je pc_type

cmp AL, 0FEh
je pc_xt_type

cmp AL, 0FDh
je pcjr_type

cmp AL, 0FCh
je at_type

cmp AL, 0FCh
je ps2_5060

cmp AL, 0FBh
je pc_xt_type

cmp AL, 0FAh
je ps2_30

cmp AL, 0F8h
je ps2_80

cmp AL, 0F9h
je pc_conv

pc_type:
mov DX, offset PC
jmp end_proc

pc_xt_type:
mov DX, offset PC_XT
jmp end_proc

pcjr_type:
mov DX, offset PCjr
jmp end_proc

at_type:
mov DX, offset AT
jmp end_proc

ps2_5060:
mov DX, offset PS25060
jmp end_proc

ps2_80:
mov DX, offset PS280
jmp end_proc

ps2_30:
mov DX, offset PS230
jmp end_proc

pc_conv:
mov DX, offset PC_convert
jmp end_proc

end_proc:
call PRINT_STRING
ret

PCTYPE_CHECKING ENDP 

OS_CHECKING PROC near
mov AH, 30h
int 21h
push AX

mov SI, offset DOS_vs
add si, 16
call BYTE_TO_DEC
pop AX
add SI, 3
mov AL, AH
call BYTE_TO_DEC
mov DX, offset DOS_vs
call PRINT_STRING

mov SI, offset OEM_num
add SI, 13
mov AL, BH
call BYTE_TO_DEC
mov DX, offset OEM_num
call PRINT_STRING

mov DI, offset USER_num
add DI, 18
mov AX, CX
call WRD_TO_HEX
mov AL, BL
call BYTE_TO_HEX
mov DI, offset USER_num
add DI, 13
mov [DI], AX
mov DX, offset USER_num
call PRINT_STRING
ret

end_proc2:
ret

OS_CHECKING ENDP
; КОД
BEGIN:
 call PCTYPE_CHECKING
 call OS_CHECKING
 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа