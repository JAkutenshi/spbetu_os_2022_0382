OVERLAY1 SEGMENT
ASSUME CS:OVERLAY1, DS:NOTHING, SS:NOTHING

MAIN PROC FAR

    push AX
    push DX
    push DI
    push DS
    
    mov AX,CS
    mov DS,AX
    mov DI,offset ovl_addr + 22
    call WRD_TO_HEX
    mov DX,offset ovl_addr
    call _PRINT
    
    pop ds
    pop di
    pop dx
    pop ax
    retf
    
MAIN ENDP

ovl_addr db "Overlay 1 address:     H", 0DH, 0AH, '$'

_PRINT PROC NEAR

    push ax
    
    mov ah, 09h
    int 21h
    
    pop ax
    ret
    
_PRINT ENDP


TETR_TO_HEX PROC NEAR

    and AL,0Fh
    cmp AL,09
    jbe next
    add AL,07
  next:
    add AL,30h
    ret
    
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR

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

WRD_TO_HEX PROC NEAR

    push bx
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

OVERLAY1 ENDS
END MAIN
