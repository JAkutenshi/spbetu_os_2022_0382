TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN
; Данные
PC db  'PC type: PC',0DH,0AH,'$'
PC_XT db 'PC type: PC/XT',0DH,0AH,'$'
AT db  'PC type: AT',0DH,0AH,'$'
PS2_30 db 'PC type: PS2 model 30',0DH,0AH,'$'
PS2_50_or_60 db 'PC type: PS2 model 50 or 60',0DH,0AH,'$'
PS2_80 db 'PC type: PS2 model 80',0DH,0AH,'$'
PCJR db 'PC type: PСjr',0DH,0AH,'$'
PC_CONVERTIBLE db 'PC type: PC Convertible',0DH,0AH,'$'

DOS_VERS db 'DOS version:  .  ',0DH,0AH,'$'
OEM_NUMBER db  'OEM serial number:   ',0DH,0AH,'$'
USER_NUMBER db  'User serial number:       h', 0DH, 0AH,'$'

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

PRINT_STRING PROC near
    mov AH, 09h
    int 21h
    ret
PRINT_STRING ENDP

PC_TYPE PROC near
    mov AX, 0F000h
    mov ES, AX
    mov AL, ES:[0FFFEh]
    
    cmp AL, 0FFh
    je t_pc

    cmp AL, 0FEh
    je t_pc_xt

    cmp AL, 0FBh
    je t_pc_xt

    cmp AL, 0FCh
    je t_at

    cmp AL, 0FAh
    je t_ps2_30

    cmp AL, 0FCh
    je t_ps2_50_or_60

    cmp AL, 0F8h
    je t_ps2_80

    cmp AL, 0FDh
    je t_pcjr

    cmp AL, 0F9h
    je t_pc_convertible

t_pc:
    mov DX, offset PC
    jmp final_1

t_pc_xt:
    mov DX, offset PC_XT
    jmp final_1

t_at:
    mov DX, offset AT
    jmp final_1

t_ps2_30:
    mov DX, offset PS2_30
    jmp final_1

t_ps2_50_or_60:
    mov DX, offset PS2_50_or_60
    jmp final_1

t_ps2_80:
    mov DX, offset PS2_80
    jmp final_1

t_pcjr:
    mov DX, offset PCJR
    jmp final_1

t_pc_convertible:
    mov DX, offset PC_CONVERTIBLE
    jmp final_1

final_1:
    call PRINT_STRING
    ret
PC_TYPE ENDP  

S_VERSION PROC near
    mov AH,30h
    int 21h
    ;push AX
   
    mov SI, offset DOS_VERS
    add SI, 13
    call BYTE_TO_DEC
    ;pop AX
    mov AL,AH
    add SI,3
    call BYTE_TO_DEC
    mov DX, offset DOS_VERS
    call PRINT_STRING

    mov SI, offset OEM_NUMBER
    add SI, 21
    mov AL, BH
    call BYTE_TO_DEC
    mov DX, offset OEM_NUMBER
    call PRINT_STRING

    mov DI, offset USER_NUMBER
    add DI, 25
    mov AX, CX
    call WRD_TO_HEX
    mov AL, BL
    call BYTE_TO_HEX
    mov DI, offset USER_NUMBER
    add DI, 20
    mov [DI], AX
    mov DX, offset USER_NUMBER
    call PRINT_STRING
   
    ret
 
S_VERSION ENDP 

; Код
BEGIN:
    call PC_TYPE
    call S_VERSION
    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
END START 