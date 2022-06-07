TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN


unavailable_memory db 		'Unavailable memory segment address:     ', 0DH, 0AH, '$'

environment db 				'Environment segment address:     ', 0DH, 0AH, '$'

environment_area db 		'Environment area content:   ', 0DH, 0AH, '$'

empty db 					'empty', 0DH, 0AH, '$'

endl db                      0DH, 0AH, '$'

command_line_tail db 		'Tail of command line :$'

module_path db 				'Loaded module path :$'


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
print_word proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print_word endp

print_byte proc near
	push ax
	mov ah, 02h
	int 21h
	pop ax
	ret
print_byte endp

;------------------------------------------

unavailable_memory_print proc near
	push ax
	push di
	push dx

	mov ax, ds:[02h]
	mov di, offset unavailable_memory
	add di, 39
	call wrd_to_hex
	mov dx, offset unavailable_memory

	call print_word
	
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
	add di, 32
	call wrd_to_hex
	mov dx, offset environment

	call print_word

	pop dx
	pop di
	pop ax

	ret
environment_print endp

command_line_tail_print proc near
	push di
	push cx
	push dx

	mov dx, offset command_line_tail
	call print_word
	xor cx, cx
	xor di, di
	mov cl, ds:[80h]
	cmp cl, 0h
	je empty_tail
	
	read_tail:
		mov dl, ds:[81h+di]
		call print_byte
		inc di
	loop read_tail

	mov dx, offset endl
	call print_word
	
	jmp final
		
	empty_tail:
		mov dx, offset empty
		call print_word

	final:
		pop dx
		pop cx
		pop di
	ret
command_line_tail_print endp


print_env_path proc near
	push ax
	push di
	push dx
	push es

	mov dx, offset environment_area
	call print_word
	xor di, di
	mov ax, ds:[2ch]
	mov es, ax

	read_content:
		mov dl, es:[di]
		cmp dl, 0h
		je separator_word
		call print_byte
		inc di
		jmp read_content

	separator_word:
		mov dl, 0ah
		call print_byte
		inc di
		mov dl, es:[di]
		cmp dl, 0h
		je read_path
		call print_byte
		inc di
		jmp read_content
	
	read_path:
		add di, 3					;skip 2 bytes
		mov dx, offset module_path
		call print_word
		
		read_b:
			mov dl, es:[di]
			cmp dl, 0h
			je final_1
			call print_byte
			inc di
			jmp read_b
	final_1:
		pop es
		pop dx
		pop di
		pop ax
	ret
print_env_path endp


BEGIN:
	call unavailable_memory_print
	call environment_print
	call command_line_tail_print
	call print_env_path

	xor al, al
	mov ah, 4ch
	int 21h
	
TESTPC ENDS
END START