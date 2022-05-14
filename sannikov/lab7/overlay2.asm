ASSUME CS:CODE
CODE SEGMENT
    MAIN PROC FAR
        push ax
        push dx
        push ds
        push di

        mov ax, cs
        mov ds, ax
        mov di, offset OVERLAY_ADDR
        add di, 22
        call WRD_TO_HEX
        mov dx, offset OVERLAY_ADDR
        call PRINT

        pop di
        pop ds
        pop dx
        pop ax
        retf
    MAIN ENDP

    OVERLAY_ADDR db "Overlay 2 address: 0000h$", 0dh,0ah,'$'

    PRINT PROC
        push ax
        mov ah, 9h
        int 21h
        pop ax
        ret
    PRINT ENDP

    TETR_TO_HEX proc near
    and al, 0fh
    cmp al, 09
    jbe next
    add al, 07
    next:
    	add al, 30h
    	ret
    TETR_TO_HEX endp


BYTE_TO_HEX proc near
    push cx
    mov ah, al
    call TETR_TO_HEX
    xchg al, ah
    mov cl, 4
    shr al, cl
    call TETR_TO_HEX
    pop cx
    ret
BYTE_TO_HEX endp


WRD_TO_HEX PROC NEAR
    push bx
    mov	bh, ah
    call BYTE_TO_HEX
    mov	[di], ah
    dec	di
    mov	[di], al
    dec	di
    mov	al, bh
    xor	ah, ah
    call BYTE_TO_HEX
    mov	[di], ah
    dec	di
    mov	[di], al
    pop	bx
    ret
WRD_TO_HEX ENDP

CODE ENDS
END MAIN
