overlay segment
	assume cs:overlay, ds:nothing, ss:nothing

main proc far
	push ax
	push dx
	push ds
	push di
	
	mov ax, cs ;;
	mov ds, ax
	
	mov di, offset message_add
 	add di, 24
	call wrd_to_hex
	mov dx, offset message_add
	call print
	pop di
	pop ds
	pop dx
	pop ax
	retf
main endp



message_add db 13, 10, "overlay_1 address:     ", 13, 10, '$'
   


print proc 
      	push dx
      	push ax
      	mov ah, 09h
      	int 21h
	pop ax
	pop dx
	ret
print endp


tetr_to_hex proc 
      	and al, 0fh
      	cmp al, 09
      	jbe next
      	add al, 07
next:
      	add al, 30h
      	ret
tetr_to_hex endp


byte_to_hex proc     
      	push cx
      	mov ah, al
      	call tetr_to_hex
     	xchg al, ah
      	mov cl, 4
      	shr al, cl
      	call tetr_to_hex   
      	pop cx             
      	ret
byte_to_hex endp


wrd_to_hex proc
      	push bx
      	mov bh, ah
      	call byte_to_hex
      	mov [di], ah
      	dec di
      	mov [di], al
      	dec di
      	mov al, bh
      	xor ah, ah
      	call byte_to_hex
      	mov [di], ah
      	dec di
      	mov [di], al
      	pop bx
      	ret
wrd_to_hex endp
overlay ends

end main 