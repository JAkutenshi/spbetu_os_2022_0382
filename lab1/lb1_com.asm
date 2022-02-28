; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

START: JMP BEGIN

; ДАННЫЕ
PC db 'PC TYPE: PC',0DH,0AH,'$'
PC_XT db 'PC TYPE: PC/XT',0DH,0AH,'$'
AT db 'PC TYPE: AT',0DH,0AH,'$'
PS2_30 db 'PC TYPE: PS2 model 30',0DH,0AH,'$'
;PS2_50_60 db 'PC TYPE: PS2 model 50 or 60',0DH,0AH,'$'
PS2_80 db 'PC TYPE: PS2 model 80',0DH,0AH,'$'
PCjr db 'PC TYPE: PCjr',0DH,0AH,'$'
PC_Convertible db 'PC TYPE: PC Convertible',0DH,0AH,'$'
PC_Unknown db 'PC TYPE:  ',0DH,0AH,'$'

VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
SERIAL_NUMBER db  'Serial number OEM:   ',0DH,0AH,'$'
USER_NUMBER db  'User serial number:       H $'


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

print_dx PROC near
    mov AH,09h
    int 21h
    ret
print_dx ENDP

PRINT_PC_TYPE PROC near
    mov ax, 0F000h
    mov es, ax
    mov ah, es:[0FFFEh]

pc_l:
    cmp ah, 0FFh
    jne pc_xt_l_1
    mov dx, offset PC
    JMP final

pc_xt_l_1:
    cmp ah, 0FEh
    jne pc_xt_l_2
    mov dx, offset PC_XT
    JMP final

pc_xt_l_2:
    cmp ah, 0FBh
    jne at_l
    mov dx, offset PC_XT
    JMP final

at_l:
    cmp ah, 0FCh
    jne ps2_30_l
    mov dx, offset AT
    JMP final

ps2_30_l:
    cmp ah, 0FAh
    jne ps2_80_l
    mov dx, offset PS2_30
    JMP final

ps2_80_l:
    cmp ah, 0F8h
    jne pcjr_l
    mov dx, offset PS2_80
    JMP final

pcjr_l:
    cmp ah, 0FDh
    jne pc_convertible_l
    mov dx, offset PCjr
    JMP final

pc_convertible_l:
    cmp ah, 0F9h
    jne pc_unknown_l
    mov dx, offset PC_Convertible
    JMP final

pc_unknown_l:
    mov di, offset PC_Unknown + 10
    mov al, ah
    call BYTE_TO_HEX
    mov [di], AX
    mov dx, offset PC_Unknown

final:
    call print_dx
    ret
PRINT_PC_TYPE ENDP

PRINT_VER_OS PROC near
   mov ah,30h
   int 21h
   push ax
   
   mov si,offset VERSIONS
   add si,16
   call BYTE_TO_DEC
   pop ax
   add si,3
   mov al,ah
   call BYTE_TO_DEC
   mov dx,offset VERSIONS
   call print_dx

   mov si,offset SERIAL_NUMBER
   add si,21
   mov al,bh
   call BYTE_TO_DEC
   mov dx ,offset SERIAL_NUMBER
   call print_dx

   mov di, offset USER_NUMBER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di,2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call print_dx
	ret

final_2:
   ret
PRINT_VER_OS ENDP

; КОД
BEGIN:
    call PRINT_PC_TYPE
    call PRINT_VER_OS
; Выход в DOS
    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
    END START ;конец модуля, START - точка входа
