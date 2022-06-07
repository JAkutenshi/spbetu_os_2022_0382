; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN

; ДАННЫЕ
SEG_ADR_MEM_D db 'Segment address of unavailable memory:     h',0DH,0AH,'$'
SEG_ADR_ENV_D db 'Segment address of the environment:     h',0DH,0AH,'$'
TAIL_COMM_LINE_D db 'The tail of the command line in symbolic form: ','$'
EMPTY_TAIL_COMM_LINE_D db 'The tail of the command is empty',0DH,0AH,'$'
CONT_ENV_AREA_D db 'The contents of the environment area in symbolic form: ',0DH,0AH,'$'
PATH_LOAD_MODULE_D db 'The path of the loaded module: ','$'


;Процедуры
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP

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

print_str PROC near
    mov AH, 09h
    int 21h
    ret
print_str ENDP

print_symb PROC near
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
print_symb ENDP

LAB2 PROC near
    push AX
	push CX
	push DX
	push DI
	push ES

    mov ax, ds:[2h]
    mov di, offset SEG_ADR_MEM_D + 42
    call WRD_TO_HEX
    mov dx, offset SEG_ADR_MEM_D
    call print_str

    mov ax, ds:[2Ch]
    mov di, offset SEG_ADR_ENV_D + 39
    call WRD_TO_HEX
    mov dx, offset SEG_ADR_ENV_D
    call print_str

    mov cl, ds:[80h]
    cmp cl, 0h
    jne normal_command_tail
    mov dx, offset EMPTY_TAIL_COMM_LINE_D
    call print_str
    jmp cont_env
normal_command_tail:
    mov dx,offset TAIL_COMM_LINE_D
    call print_str
    mov di,81h
loop_command_tail:
    mov dl, ds:[di]
    call print_symb
    inc di
    loop loop_command_tail
    mov dl, 0Dh
    call print_symb
    mov dl, 0Ah
    call print_symb
cont_env:

    mov dx, offset CONT_ENV_AREA_D
    call print_str
    mov es, ds:[2Ch]
    xor di, di
loop_cont_env:
    mov dl, es:[di]
    cmp dl, 0h
    je final_cont_env
    call print_symb
    inc di
    jmp loop_cont_env
final_cont_env:
    mov dl, 0Dh
    call print_symb
    mov dl, 0Ah
    call print_symb
    inc di
    mov dl, es:[di]
    cmp dl, 0h
    jne loop_cont_env

    mov di, 3
    mov dx, offset PATH_LOAD_MODULE_D
    call print_str
loop_path:
    mov dl, es:[di]
    cmp dl, 0h
    je final_path
    call print_symb
    inc di
    jmp loop_path
final_path:
    mov dl, 0Dh
    call print_symb
    mov dl, 0Ah
    call print_symb
    
    pop ES
	pop DI
	pop DX
	pop CX
	pop AX

    ret
LAB2 ENDP


; КОД
BEGIN:
    call LAB2
; Выход в DOS
    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
    END START ;конец модуля, START - точка входа