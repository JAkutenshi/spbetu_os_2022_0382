TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN

; Данные
AV_MEM db 'Amount of available memory:        b$'
EX_MEM db 'Size of extended memory:       Kb$'
MCB_TABLE db 'MCB table:$'
MCB_STRING db 'MCB type:   , MCB adress:     , PSP adress:     , Size:       , SC/CD: $' 
ENDL db 0DH, 0AH, '$'

; Процедуры
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe next
    add AL,07
next:
    add AL,30h
    ret
TETR_TO_HEX ENDP

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

WRD_TO_DEC PROC near
    push cx
    push dx
    mov cx, 10
wloop_bd:   
    div cx
    or dl, 30h
    mov [si], dl
    dec si
    xor dx, dx
    cmp ax, 10
    jae wloop_bd
    cmp al, 00h
    je wend_l
    or al, 30h
    mov [si], al
wend_l:      
    pop dx
    pop cx
    ret
WRD_TO_DEC ENDP

PRINT_STRING PROC near
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
PRINT_STRING ENDP

PRINT_SYMB PROC near
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
PRINT_SYMB ENDP

AVMEM PROC near
    mov ah, 4Ah
    mov bx, 0FFFFh
    int 21h

    mov ax, bx
    mov cx, 10h
    mul cx
    mov si, offset AV_MEM+33
    call WRD_TO_DEC
    mov dx, offset AV_MEM
    call PRINT_STRING
    mov dx, offset ENDL
    call PRINT_STRING
    ret
AVMEM ENDP

EXMEM PROC near
    mov	al, 30h
    out	70h, al
    in	al, 71h
    mov	bl, al
    mov	al, 31h
    out	70h, al
    in	al, 71h
    mov	ah, al
    mov	al, bl
    mov	si, offset EX_MEM+29
    xor dx, dx
    call WRD_TO_DEC
    mov	dx, offset EX_MEM
    call PRINT_STRING
    mov	dx, offset ENDL
    call PRINT_STRING
    ret
EXMEM ENDP

MCB PROC near
    mov	dx, offset MCB_TABLE
    call PRINT_STRING
    mov	dx, offset endl
    call PRINT_STRING
    
    mov	ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax

circle:
    ;type
    mov al, es:[0000h]
    call BYTE_TO_HEX
    mov	di, offset MCB_STRING+10
    mov [di], ax
    
    ;adress
    mov di, offset MCB_STRING+29
    mov ax, es
    call WRD_TO_HEX

    ;PSP adress
    mov ax, es:[0001h]
    mov di, offset MCB_STRING+47
    call WRD_TO_HEX

    ;size
    mov ax, es:[0003h]
    mov cx, 10h 
    mul cx
    mov	si, offset MCB_STRING+61
    call WRD_TO_DEC

    mov dx, offset MCB_STRING
    call PRINT_STRING

    ;SC_CD
    mov bx, 8
    mov cx, 7
l_loop:
    mov dl, es:[bx]
    call PRINT_SYMB
    inc bx
    loop l_loop

    mov al, es:[0000h]
    cmp al, 5ah
    je final 
 
    mov ax, es
    add ax, es:[0003h]
    inc ax
    mov es, ax 
    mov dx, offset ENDL
    call PRINT_STRING
    jmp circle

final:
     ret

MCB ENDP

BEGIN:
    call AVMEM
    call EXMEM
    call MCB
    xor AL, AL
    mov AH, 4Ch
    int 21h
TESTPC ENDS
END START 