TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN


unavailable_memory db 		'Address of unavailable memory segment:     ', 0DH, 0AH, '$'

environment db 				'Address of environment segment:     ', 0DH, 0AH, '$'

environment_area db 		'Contents of environment area:   ', 0DH, 0AH, '$'

empty db 					'empty', 0DH, 0AH, '$'

command_line_tail db 		'End of command line:$'

module_path db 				'Path of loaded module:$'


tetr_to_hex proc near
		and al, 0fh
		cmp al, 09
		jbe next
		add al, 07
next:	add al, 30h
		ret
tetr_to_hex endp

byte_to_hex	proc near
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

wrd_to_hex proc near
		push bx
		mov bh, ah
		call byte_to_hex
		mov [di], ah
		dec di
		mov [di], al
		dec di
		mov al, bh
		call byte_to_hex
		mov [di], ah
		dec di
		mov [di], al
		pop bx
		ret
wrd_to_hex endp

byte_to_dec proc near
		push cx
		push dx
		xor ah, ah
		xor dx, dx
		mov cx, 10
loop_bd:	div cx
		or dl, 30h
		mov [si], dl
		dec si
		xor dx, dx
		cmp ax, 10
		jae loop_bd
		cmp al, 00h
		je end_l
		or al, 30h
		mov [si], al
end_l:	pop dx
		pop cx
		ret
byte_to_dec endp

;----------------------------------------
write_message_word proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
write_message_word endp


write_message_byte proc near
	push ax
	mov ah, 02h
	int 21h
	pop ax
	ret
write_message_byte endp

;------------------------------------------



unavailable_memory_print proc near
	push ax
	push di
	push dx

	mov ax, ds:[02h]
	mov di, offset unavailable_memory
	add di, 42
	call wrd_to_hex
	mov dx, offset unavailable_memory

	call write_message_word
	
	pop dx
	pop di
	pop ax

	ret
unavailable_memory_print endp

environment_print proc near
	push ax
	push di
	push dx

	mov ax, ds:[02ch]
	mov di, offset environment
	add di, 35
	call wrd_to_hex
	mov dx, offset environment

	call write_message_word

	pop dx
	pop di
	pop ax

	ret
environment_print endp

command_line_tail_print proc near
	push ax
	push di
	push cx
	push dx

	mov dx, offset command_line_tail
	call write_message_word
	
	xor cx, cx

	mov cl, ds:[80h]
	cmp cl, 0h
	
	
	je empty_tail
	xor di, di


	cycle:
		mov dl, ds:[81h+di]
		call write_message_byte
		inc di
	loop cycle
	;----
	
	
	mov dl, 0dh
	call write_message_byte
	mov dl, 0ah
	call write_message_byte
	
	jmp final
		
	empty_tail:
		mov dx, offset empty
		call write_message_word

	final:
		pop dx
		pop cx
		pop di
		pop ax
	ret
command_line_tail_print endp


print_content_env_area_and_loaded_module_path proc near
	push ax
	push di
	push dx
	push es

	mov dx, offset environment_area
	call write_message_word
	xor di, di
	mov ax, ds:[2ch]
	mov es, ax

	cycle_02:
		mov dl, es:[di]
		cmp dl, 0h
		je end_word
		call write_message_byte
		inc di
		jmp cycle_02

	end_word:
		mov dl, 0ah
		call write_message_byte
		inc di
		mov dl, es:[di]
		cmp dl, 0h
		je final_02
		call write_message_byte
		inc di
		jmp cycle_02
	
	final_02:
		mov dx, offset module_path
		call write_message_word
		add di, 3
		cycle_03:
			mov dl, es:[di]
			cmp dl, 0h
			je final_03
			call write_message_byte
			inc di
			jmp cycle_03

	final_03:
		pop es
		pop dx
		pop di
		pop ax
	ret
print_content_env_area_and_loaded_module_path endp

BEGIN:
	call unavailable_memory_print
	call environment_print
	call command_line_tail_print
	call print_content_env_area_and_loaded_module_path

	xor al, al
	
	mov AH, 1   ; wait
	int 21h
	
	mov AH,4Ch  
	int 21H

	
TESTPC ENDS
END START