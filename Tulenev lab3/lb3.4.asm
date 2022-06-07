; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

START: JMP BEGIN

; ДАННЫЕ
MEM_SIZE db 'MEM_SIZE:                  ',0DH,0AH,'$'
EXTEND_MEM_SIZE db 'EXTEND_MEM_SIZE:                  ',0DH,0AH,'$'
MCU db 'Memory control unit: adress-      ; type of part-      ; size of part-        ; SC or SD-              ',0DH,0AH,'$'
WORNING db 0DH,0AH, '                 !!! WORNING !!!  !!! WORNING !!!  !!! WORNING !!!',0DH,0AH,0DH,0AH,'$'

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

WRD_TO_DEC PROC near
; ax - paragraph, si - low digit of result
    push bx
    push dx

    mov bx, 16
    mul bx 
    mov bx, 10

    convert:
        div bx
        add dl, '0'
        mov [si], dl
        dec si
        xor dx, dx
        cmp ax, 0000h
        jne convert

    pop dx
    pop bx
    ret
WRD_TO_DEC ENDP

print_st PROC near
    mov AH, 09h
    int 21h
    ret
print_st ENDP

print_symb PROC near
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
print_symb ENDP

PRINT_MEM_SIZE PROC near
    push ax
    push dx
    push cx
    push bx
    push si

    MOV AH,4AH
    MOV BX,0FFFFH ; заведомо большая память
    INT 21H

    mov si, offset MEM_SIZE
    add si, 18
    mov ax, bx
    call WRD_TO_DEC

    mov dx, offset MEM_SIZE
    call print_st 

    pop si
    pop bx
    pop cx
    pop dx
    pop ax
    ret
PRINT_MEM_SIZE ENDP

PRINT_EXTEND_MEM_SIZE PROC near
    push ax
    push dx
    push cx
    push bx
    push si

    mov AL,30h ; запись адреса ячейки CMOS
    out 70h,AL
    in AL,71h ; чтение младшего байта
    mov BL,AL 

    mov AL,31h ; запись адреса ячейки CMOS
    out 70h,AL
    in AL,71h 
    mov BH,AL 

    mov si, offset EXTEND_MEM_SIZE
    add si, 25
    mov ax, bx
    call WRD_TO_DEC

    mov dx, offset EXTEND_MEM_SIZE
    call print_st 

    pop si
    pop bx
    pop cx
    pop dx
    pop ax
    ret
PRINT_EXTEND_MEM_SIZE ENDP

PRINT_MCU PROC near
    push ax
    push dx
    push cx
    push bx
    push si

    mov di, offset MCU
    add di, 33
    mov ax, es
    call WRD_TO_HEX

    mov di, offset MCU
    add di, 54
    mov ax, es:[01h]
    call WRD_TO_HEX

    mov si, offset MCU
    add si, 77
    mov ax, es:[03h]
    call WRD_TO_DEC

    mov di, offset MCU
    add di, 91
    mov si, 8

sc_sd:
    mov bx, es:[si]
	mov [di], bx
    add si, 2
	add di, 2
    cmp si, 16
	jb sc_sd

    mov dx, offset MCU
    call print_st 

    pop si
    pop bx
    pop cx
    pop dx
    pop ax
    ret
PRINT_MCU ENDP

PRINT_CHAIN_MCU PROC near
    push ax
    push dx
    push cx
    push bx
    push si
    push es

    mov ah, 52h
    int 21h
    mov es, es:[bx-2]

chain:
    call PRINT_MCU
    mov ah, es:[0]
    cmp ah, 5Ah
    je end_
    mov ax, es
    add ax, es:[3]
    inc ax
    mov es, ax
    jmp chain

end_:        
    pop es
    pop si
    pop bx
    pop cx
    pop dx
    pop ax
    ret
PRINT_CHAIN_MCU ENDP

CLEAN_MEM PROC near
    push ax
    push bx
    push dx

    mov ax, offset FINAL_LB3
    mov bx, 10h
    xor dx, dx
    div bx
    inc ax
    mov bx, ax
    mov al, 0
    mov ah, 4ah
    int 21h

    pop dx
    pop bx
    pop ax
    ret
CLEAN_MEM ENDP

EXTRA_MEM PROC near
     push ax
    push bx
    push dx

    mov bx, 1000h
    mov ah, 48h
    int 21h

    jnc end_ask
    mov dx, offset WORNING   
    call print_st

end_ask:
    pop dx
    pop bx
    pop cx
    ret
EXTRA_MEM ENDP

; КОД
BEGIN:
    call PRINT_MEM_SIZE
    call PRINT_EXTEND_MEM_SIZE
    call CLEAN_MEM
    call EXTRA_MEM
    call PRINT_CHAIN_MCU
; Выход в DOS
    xor AL,AL
    mov AH,4Ch
    int 21H
FINAL_LB3:
TESTPC ENDS
    END START ;конец модуля, START - точка входа