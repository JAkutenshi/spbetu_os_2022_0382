TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN


;types PC
PC db 'Type IBM PC: PC',0DH,0AH,'$' ;FF
PCXT db 'Type IBM PC: PC/XT',0DH,0AH,'$' ;FE, FB
AT db 'Type IBM PC: AT',0DH,0AH,'$' ;FC
PS2_30 db 'Type IBM PC: PS model 30',0DH,0AH,'$' ;FA
PS2_80 db 'Type IBM PC: PC model 80',0DH,0AH,'$' ;F8
PCJR db 'Type IBM PC: PCjr',0DH,0AH,'$' ;FD
PCC db 'Type IBM PC: PC Convertible',0DH,0AH,'$' ;F9

VERSION db 'MS DOS version: 01.00 ',0DH,0AH,'$'
OEM_MES db 'OEM:    ',0DH,0AH,'$'
USER db 'User:       H',0DH,0AH,'$'



WRITE_MES MACRO mes
    mov DX, offset mes
    mov AH, 09h
    int 21h
ENDM

CHECK_TYPE_PC MACRO val, pctype
    cmp AL, val
    jne @f
    WRITE_MES pctype
    jmp DOS_VESION
@@: 
ENDM


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
    mov [SI],AH
    dec SI
    mov [SI],AL
    dec SI
    mov AL,BH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
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


BEGIN:
    mov BX, 0F000h
    mov ES, BX
    mov AL, ES:[0FFFEh]
	
    CHECK_TYPE_PC 0FFh, PC
    CHECK_TYPE_PC 0FEh, PCXT
    CHECK_TYPE_PC 0FBh, PCXT
    CHECK_TYPE_PC 0FDh, PCJR
    CHECK_TYPE_PC 0FCh, AT
    CHECK_TYPE_PC 0FAh, PS2_30
    CHECK_TYPE_PC 0F8h, PS2_80
    CHECK_TYPE_PC 0F9h, PCC

UNKNOWN_TYPE_PC:
    call BYTE_TO_HEX
    mov BH, AH
    mov DL, AL
    mov AH, 06h
    int 21h
    mov DL, BH
    int 21h
	
DOS_VESION:
    mov AH, 30h
    int 21h
    mov SI, offset VERSION
    add SI, 17
    cmp AL, 00h
    je MODIFICATION
    mov DH, AH
    call BYTE_TO_DEC ; AL -> VERSION[17] (= SI)
    mov AL, DH
	
MODIFICATION:
    add SI, 3
    call BYTE_TO_DEC ; AL -> VERSION[20]  (= SI)
    WRITE_MES VERSION

OEM:
    mov AL, BH
    mov SI, offset OEM_MES
    add SI, 7
    call BYTE_TO_DEC
    WRITE_MES OEM_MES	

USER_NUM:
    mov SI, offset USER
    add SI, 11
    mov AX, CX
    call WRD_TO_HEX ; AX -> USER[11]  (= SI)
	mov AL, BL
    call BYTE_TO_HEX ;AL -> junior rank = AH ,senior rank = AL 
	sub SI, 2
    mov [SI], AX
    WRITE_MES USER
	
	;EXIT
    xor AL,AL
    mov AH,4Ch
    int 21H
	
TESTPC ENDS
    END START 