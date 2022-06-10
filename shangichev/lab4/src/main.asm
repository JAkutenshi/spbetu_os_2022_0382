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

get_curs proc near

	mov AH, 03h
	mov BH, 0
	int 10h

	ret
get_curs endp


set_curs proc near

	mov AH, 02h
	mov BH, 0
	int 10h

	ret
set_curs endp


rout proc far
	jmp start
	signature dw 1234h
	number db 'Interrupt has been called 0000 times.$'
	keep_psp dw 0
	keep_cs dw 0
	keep_ip dw 0
	keep_ss dw 0
	keep_sp dw 0
	keep_ax dw 0
	IStack db 128 dup(?)

	start:
		mov keep_ax, ax
		mov ax, ss
		mov keep_ss, ax
		mov keep_sp, sp
		mov ax, seg IStack
		mov ss, ax
		mov sp, offset start

		push cx
		push dx

		call GET_CURS
		push dx

		mov dh, 0
		mov dl, 0
		call SET_CURS
		push si

		push cx
		push ds
		push bp

		mov ax, seg number
		mov ds, ax
		mov si, offset number
		add si, 25
		mov cx, 4

	loop_int:
		mov bp, cx
		mov ah, [si+bp]
		inc ah
		mov [si+bp], ah
		cmp ah, 3Ah
		jne print_msg
		mov ah, 30h
		mov [si+bp], ah
		loop loop_int

	print_msg:
		pop bp
		pop ds
		pop cx
		pop si
		
		push es
		push bp

		mov ax, seg number
		mov es, ax
		mov ax, offset number
		mov bp, ax
		mov ah, 13h
		mov al, 0
		mov cx, 37
		mov bh, 0
		int 10h

		pop bp
		pop es
		
		pop dx
		call SET_CURS
		
		pop dx
		pop cx

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

	mov ax, 351Ch
	int 21h
	mov keep_ip, bx
	mov keep_cs, es

	push ds
	mov dx, offset rout
	mov ax, seg rout
	mov ds, ax
	mov ax, 251Ch
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
	mov AL, 1Ch
	int 21h

	cli 
	push ds
	mov ax, es:[keep_cs]
	mov ds, ax
	mov dx, es:[keep_ip]
	mov ah, 25h
	mov al, 1Ch
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


	mov ax, 351Ch
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
