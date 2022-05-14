CODE SEGMENT
    ASSUME CS:CODE, DS:NOTHING, SS:NOTHING

MAIN proc far
    push ax
    push dx
    push ds
    push di

    mov ax, cs
    mov ds, ax
    mov di, offset OVL_ADDR
    add di, 17
    call WRD_TO_HEX
    mov dx, offset OVL_ADDR
    call PRINT_STRING

    pop di
    pop ds
    pop dx
    pop ax
    retf
Main ENDP

OVL_ADDR db "ovl1 address:    ", 0AH, 0DH, 0AH, '$'

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
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

PRINT_STRING PROC near
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
PRINT_STRING ENDP

CODE ENDS
END Main