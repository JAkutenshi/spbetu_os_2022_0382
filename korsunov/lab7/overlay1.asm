CODE SEGMENT

	ASSUME CS:CODE, DS:NOTHING, SS:NOTHING
	MAIN PROC far
		push AX
		push DX
		push DS
		push DI
		
		mov AX, CS
		mov DS, AX
		mov DI, offset overlay1_address_str
		add DI, 25
		call WRD_TO_HEX
		mov DX, offset overlay1_address_str
		call WRITE_MESSAGE_WORD
		
		pop DI
		pop DS
		pop DX
		pop AX
		retf
	MAIN ENDP

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

    WRD_TO_HEX proc near
        push bx
        mov bh, ah
        call BYTE_TO_HEX
        mov [di], ah
        dec di
        mov [di], al
        dec di
        mov al, bh
        call BYTE_TO_HEX
        mov [di], ah
        dec di
        mov [di], al
        pop bx
        ret
    WRD_TO_HEX endp
	
	WRITE_MESSAGE_WORD  PROC  near 
        push AX
		
        mov AH, 9
        int 21h
		
        pop AX
        ret
    WRITE_MESSAGE_WORD  ENDP
	
	overlay1_address_str db 'Overlay 1 address is:      ', 0DH, 0AH, '$'

CODE ENDS
END MAIN