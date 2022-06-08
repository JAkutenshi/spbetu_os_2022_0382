OVERLAY SEGMENT
	ASSUME CS:OVERLAY, DS:NOTHING, SS:NOTHING

MAIN PROC FAR
	push ax
	push dx
	push ds
	push di
	mov ax, cs
	mov ds, ax
	mov di, offset message_add
 	add di, 23
	call WRD_TO_HEX
	mov dx, offset message_add
	call PRINT_STRING
	pop di
	pop ds
	pop dx
	pop ax
	retf
MAIN endp


message_add db 13, 10, "overlay1 address:     ", 13, 10, '$'
   

PRINT_STRING PROC 
      	push dx
      	push ax
      	mov ah, 09h
      	int 21h
	pop ax
	pop dx
	ret
PRINT_STRING ENDP


TETR_TO_HEX PROC 
      	and al, 0fh
      	cmp al, 09
      	jbe next
      	add al, 07
next:
      	add al, 30h
      	ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC     
      	push cx
      	mov ah, al
      	call TETR_TO_HEX
     	xchg al, ah
      	mov cl, 4
      	shr al, cl
      	call TETR_TO_HEX   
      	pop cx             
      	ret
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC
      	push bx
      	mov bh, ah
      	call BYTE_TO_HEX
      	mov [di], ah
      	dec di
      	mov [di], al
      	dec di
      	mov al, bh
      	xor ah, ah
      	call BYTE_TO_HEX
      	mov [di], ah
      	dec di
      	mov [di], al
      	pop bx
      	ret
WRD_TO_HEX ENDP
OVERLAY ENDS
END MAIN 