AStack   SEGMENT STACK
        DB 256 dup (?)
AStack   ENDS

DATA	SEGMENT
	not_loaded_msg db 'Interrupt is not loaded.$', 0dh, 0ah
	loaded_msg db 'Interrupt is loaded.$', 0dh, 0ah
	unloaded_msg db 'Interrupt is unloaded.$', 0dh, 0ah 
	already_loaded db 'Interrupt is already loaded.$', 0dh, 0ah

DATA ENDS

CODE   SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack


rout proc far
	jmp start
	signature dw 1234h
	keep_psp dw 0
	keep_ip dw 0
	keep_cs dw 0
	keep_ss dw 0
	keep_sp dw 0
	keep_ax dw 0
	key_sym db 0
	IStack db 50 dup(" ")

start:
	mov keep_ax, ax
	mov ax, ss
	mov keep_ss, ax
	mov keep_sp, sp
	mov ax, seg IStack
	mov ss, ax
	mov sp, offset start

	push ax
	push bx
	push cx
	push dx

	in al, 60h
	cmp al, 10h
	je q_key
	cmp al, 11h
	je w_key
	cmp al, 12h
	je e_key

	call dword ptr cs:keep_ip
	jmp exit_int

q_key:
	mov key_sym, 'r'
	jmp process_hardware_int
w_key:
	mov key_sym, 't'
	jmp process_hardware_int
e_key:
	mov key_sym, 'y'
	
process_hardware_int:
	in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al

print_key:
    	mov ah, 05h
    	mov cl, key_sym
    	mov ch, 00h
    	int 16h
    	or al, al
    	jz exit_int
    	mov ax, 40h
    	mov es, ax
    	mov ax, ES:[1Ah]
    	mov ES:[1Ch], ax
    	jmp print_key

exit_int:	
	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, keep_sp
	mov ax, keep_ss
	mov ss, ax
	mov ax, keep_ax
	mov al, 20h
	out 20h, al
	iret

	route_end:
rout endp

load_rout proc near
	push dx
	push ax
	push cx

	mov ax, 3509h
	int 21h
	mov keep_ip, bx
	mov keep_cs, es

	push ds
	mov dx, offset rout
	mov ax, seg rout
	mov ds, ax
	mov ax, 2509h
	int 21h
	pop ds

	mov dx, offset route_end
	mov cl, 4
	shr dx, cl
	inc dx
	mov ax, cs
	sub ax, keep_psp
	add dx, ax
	xor ax, ax
	mov ah, 31h
	int 21h

	pop cx
	pop ax
	pop dx

	ret
load_rout endp

unload_rout proc near
	push ax
	push bx

	mov AH, 35h
	mov AL, 09h
	int 21h

	cli 
	push ds
	mov ax, es:[keep_cs]
	mov ds, ax
	mov dx, es:[keep_ip]
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	sti

	mov ax, es:[keep_psp]
	mov es, ax
	push es
	mov ax, es:[2Ch]
	mov es, ax
	mov ah, 49h
	int 21h
	pop es
	int 21h

	pop bx
	pop ax
	ret
unload_rout endp


load_check proc near
	; return value:
	; al - nonzero if interrupt is set.
	push si
	push dx
	push bx
	push ax


	mov ax, 3509h
	int 21h
	mov si, offset signature
	sub si, offset rout
	mov dx, es:[bx + si]
	mov al, 1
	cmp dx, 1234h
	je restore
	mov al, 0

	restore:
		mov bl, al
		pop ax
		mov al, bl
		pop bx
		pop dx
		pop si
	ret
load_check endp

cmd_flag_check proc near
	; return value:
	; al - nonzero if cmd tail contains flag
	push bx

	mov al, 0
	mov bh, es:[82h]
	cmp bh, '/'
	jne end_
	mov bh, es:[83h]
	cmp bh, 'u'
	jne end_
	mov bh, es:[84h]
	cmp bh, 'n'
	jne end_
	mov al, 1


	end_:
		pop bx
	ret

cmd_flag_check endp


print proc near
	push ax
	mov ah, 09
	int 21h
	pop ax 
	ret 
print endp 
 
 
MAIN proc far 
	mov ax, data 
	mov ds, ax 
	mov keep_psp, es 
 
	call cmd_flag_check 
	mov ah, al 
	call load_check 
 
	; ah - is flag setted 
	; al - is interrupt loaded 
 
	cmp ah, 1 
	je flag_setted 

	flag_not_setted:
		cmp al, 1
		je print_already_loaded
		mov dx, offset loaded_msg
		call print
		call load_rout
		jmp finish_program

	print_already_loaded:
		mov dx, offset already_loaded
		call print
		jmp finish_program

	flag_setted:
		cmp al, 1
		jne print_not_loaded
		call unload_rout
		mov dx, offset unloaded_msg
		call print
		jmp finish_program

	print_not_loaded:
		mov dx, offset not_loaded_msg
		call print

	finish_program:
		xor ax, ax
		mov ah, 4Ch
		int 21h

	main endp
code ends
end main




