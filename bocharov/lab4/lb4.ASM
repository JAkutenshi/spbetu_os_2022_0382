assume cs:code, ds:data, ss:stack

stack segment stack
	dw 128 dup(?)
stack ends

code segment

word_to_dec proc near    ; input ax !, output ds:si
    push cx
    push dx
    push ax
    xor dx,dx
    mov cx,10
loop_bd:
    div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_bd
    cmp al,00h
    je end_l
    or al,30h
    mov [si],al
end_l: 
    pop ax
    pop dx
    pop cx
    ret
word_to_dec endp

get_curs proc near

	push ax
	push bx
	
	mov ah, 03h
	mov bh, 0
	int 10h
	
	pop bx
	pop ax
	
	ret
get_curs endp


set_curs proc near

	push ax
	push bx
	mov ah, 02h
	mov bh, 0
	int 10h

	pop bx
	pop ax
	
	ret
set_curs endp


outputbp proc  ;es:bp
	push ax
	push bx
	push dx
	push cx
	mov ah,13h ; функция
	mov al,1 ; sub function code
	mov bh,0 ; видео страница
	;mov dh,22 ; dh,dl = строка, колонка (считая от 0)
	;mov dl,0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
 ret
outputbp endp


interrupt proc far
	jmp start_int
	
	interrupt_id 	dw 0c204h
	keep_cs 		dw 0
	keep_ip 		dw 0
	
	keep_sp 		dw 0
	keep_ss 		dw 0
	keep_ax 		dw 0
	keep_psp		dw 0
	
	count 			dw 0                                               
	count_message 	db 'interrupt call count:       $'
	new_stack 		dw 128 dup(?)

start_int:
	; save
	mov keep_sp, sp
	mov keep_ax, ax
	mov keep_ss, ss
    ; stack
	mov sp, offset start_int
	mov ax, seg new_stack
	mov ss, ax

	;get_curs  
	push ax
	push bx
	push cx
	push dx 	
	
	call get_curs
	push dx 	; save curent curs

	;inc count
	push si
	push ds
	
	mov ax, seg count
	
	mov ds, ax
	
	mov si, offset count
	
	mov ax, [si]
	
	inc ax;
	
	mov [si], ax
	
	mov si, offset count_message        ; same seg
	add si, 25   
	
	call word_to_dec					; print count in dec to str
	
print_and_ret:

	pop ds
	pop si

	; print    es:bp
	push es
	push bp

	mov ax, seg count_message																									
	mov es, ax
	mov ax, offset count_message
	
	mov bp, ax
	
	; print
	mov     ah, 13h
    mov     al, 1
    mov     bh, 0
    mov     cx, 29
    mov     dx, 0
    int     10h

	pop bp
	pop es
	
	pop dx
	
	call set_curs

	pop dx
	pop cx
	pop bx
	pop ax

	mov ss, keep_ss
	mov ax, keep_ax
	mov sp, keep_sp
	
    mov     al, 20h
    out     20h, al
	
	iret
	my_int_end :
interrupt endp




load_interrupt proc near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1ch
	int 21h
	mov keep_ip, bx
	mov keep_cs, es      ; old int

	push ds
    mov dx, offset interrupt
   	mov ax, seg interrupt
    mov ds, ax
    mov ah, 25h
   	mov al, 1ch
    int 21h
	pop ds


	mov dx, offset interrupt_successfully_loaded
	call print_word

	mov dx, offset my_int_end ; mk resident
	mov cl,4
	shr dx,cl
	inc dx
	mov ax, cs
    sub ax, keep_psp
    add dx, ax
    xor ax, ax
	mov ah,31h
	int 21h                     ; exit dos



	pop es
	pop dx
	pop bx
	pop ax
	ret
load_interrupt endp


unload_interrupt proc near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h 
	mov al, 1ch 
	int 21h; es:bx - int adr

	; restre old int
	cli
	push ds
	mov dx, es:[keep_ip]
	mov ax, es:[keep_cs]
	mov ds, ax
	mov ah, 25h 
	mov al, 1ch 
	int 21h

	pop ds
	sti
	
	mov dx, offset returned_original_interrupt
	call print_word

	; mem free
	mov ax, es:[keep_psp]
	mov es, ax
	push es
	mov ax, es:[2ch]
	mov es, ax
	mov ah, 49h
	int 21h
	pop es
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	ret
unload_interrupt endp



check_interrupt proc near ; al  0 no, 1 - yes 
	push bx
	push dx
	push es

	mov ah, 35h 
	mov al, 1ch 
	int 21h

	mov si, offset interrupt_id 
	sub si, offset interrupt
	mov dx, es:[bx + si]
	mov al, 0
	cmp dx, 0c204h ; signature
	jne fin_

int_set_:
	mov al, 1

fin_:
	pop es
	pop dx
	pop bx

	ret
check_interrupt endp



check_cmd_tai proc near
	; al  0 no, 1 - yes 
	push bx

	mov al, 0
	mov bh, es:[82h]   ; es:[81h] cmd tail
	cmp bh, '\'
	jne end_
	mov bh, es:[83h]
	cmp bh, 'u'
	jne end_
	mov al, 1
	
	end_:
	
	pop bx
	ret

check_cmd_tai endp


print_word proc near
	push ax
   	mov ah, 09h
   	int 21h
	pop ax
   	ret
print_word endp


main proc far

	mov ax, data 
	mov ds, ax 
	mov keep_psp, es 
	
	call check_cmd_tai
	cmp al, 1
	je start_unload_int

	call check_interrupt
	cmp al, 1
	jne start_load

	mov dx, offset interrupt_already_loaded
	call print_word
	jmp endl

start_load:
	call load_interrupt

start_unload_int:

	call check_interrupt
	cmp al, 0
	je interrupt_not_loaded_
	call unload_interrupt
	jmp endl

interrupt_not_loaded_:
	mov dx, offset interrupt_not_loaded
	call print_word
	jmp endl

endl:
	mov ah, 4ch
	int 21h

main endp
code ends

data segment
	
	interrupt_successfully_loaded db 	'interrupt loaded', 				0dh, 0ah, '$'
	interrupt_already_loaded db 		'interruption already loaded', 		0dh, 0ah, '$'
	returned_original_interrupt db 		'interruption returned to origin', 	0dh, 0ah, '$'
	interrupt_not_loaded db 			'interruption not loaded', 			0dh, 0ah, '$'
data ends

end main